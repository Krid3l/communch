// ************
// * Communch *
// ************
// Copyright (c) 2020 Christian "Kridel" Adagas-Caou
// Licensed under the zlib license - see LICENSE.md for more information

import
    std.stdio,
    std.csv,
    std.array,
    std.algorithm,
    std.typecons,
    std.getopt,
    std.conv,
    std.datetime.systime,
    math        = std.math,            // for constants
    stdc        = core.stdc.stdlib,    // for exit()
    regex       = std.regex,
    exception   = core.exception;

struct Commune {
    int     id;         // field 1
    string  dpt_number; // field 2
    dstring name_slug;  // field 3
    dstring real_name;  // field 6
    string  postcode;   // field 9
    string  insee_code; // field 11
    int     population; // field 17
    float   land_area;  // field 19
    double  lat_deg;    // field 20
    double  lon_deg;    // field 21
    string  lat_grd;    // field 22
    string  lon_grd;    // field 23
    string  min_alt;    // field 26
    string  max_alt;    // field 27
    // fields 22-23 and 26-27 are supposed to be ints, but the CSV parser
    // errors out when trying a string to int conversion -- might be a misuse
    // of the parser on my part
}

void fetch_communes(ref const string data, ref Commune[] communes)
{
    // TODO: Add exception handling in case file is missing
    auto file = File(data, "r");
    
    // Munges data from the csv file into structs pushed into the communes
    // array - not all fields are picked up to improve performance a bit
    // and since they won't be useful in the near future
    // TODO: Abort operation if the file is corrupted
    foreach (record; file.byLine.joiner("\n").csvReader!(Tuple!(
        int, string, dstring, dstring, string, dstring, string, string,
        string, string, string, string, string, string, int, int,
        int, int, float, float, float, string, string, string,
        string, string, string))) {
        communes ~= Commune(record[0],  record[1],  record[2],  record[5],  // id, dpt_number, name_slug, real_name
                            record[8],  record[10], record[16], record[18], // postcode, insee_code, population, land_area
                            record[19], record[20], record[21], record[22], // lat_deg, lon_deg, lat_grd, lon_grd
                            record[25], record[26]);                        // min_alt, max_alt
    }
    
    writeln("Found " ~ to!string(communes.length) ~ " communes in total.");
}

// thanks to https://www.movable-type.co.uk/scripts/latlong.html
// computes the haversine (hav(theta)) from the latitude and logitude of
// the two points - for this purpose, the coordinates of two communes
// note: angles need to be in radians to be passed to trig functions,
// hence radians_given should be false when calling the function if the
// passed coordinates are in degrees for a prior conversion to happen
double haversine(double lat1, double lon1, double lat2, double lon2, bool radians_given = true)
{
    double to_rad(double degrees) { return degrees * (math.PI / 180); }

    double PHI1, PHI2, DELTA_PHI, DELTA_LAMBDA, EARTH_RADIUS = 6371e3; // metres

    if (radians_given) {
        PHI1 = lat1, PHI2 = lat2;
        DELTA_PHI    = (lat2 - lat1);
        DELTA_LAMBDA = (lon2 - lon1);
    } else {
        PHI1 = to_rad(lat1), PHI2 = to_rad(lat2);
        DELTA_PHI    = to_rad((lat2 - lat1));
        DELTA_LAMBDA = to_rad((lon2 - lon1));
    }

    // A = square half of the coord between the points
    const A = math.sin(DELTA_PHI / 2) * math.sin(DELTA_PHI / 2) +
              math.cos(PHI1) * math.cos(PHI2) *
              math.sin(DELTA_LAMBDA / 2) * math.sin(DELTA_LAMBDA / 2);
    // C = angular distance in radians
    // atan2() returns the arc tangent of its arguments' quotient
    const C = 2 * math.atan2(math.sqrt(A), math.sqrt(1 - A));

    return EARTH_RADIUS * C; // distance between the two points in metres
}

// converts INSEE codes in a Commune array into degree coordinates
void insee_to_deg_coords(ref string start, ref Commune[] communes)
{
    foreach (commune; communes) {
        if (commune.insee_code == start) {
            start = to!string(commune.lon_deg) ~ "," ~ to!string(commune.lat_deg);
        }
    }
}

// write the results in a .csv file
void write_output(ref const string[] task_args, ref Commune[] results, const double[] distances = [])
{
    // returns the current system time as an ISO string down to the second
    const string SYS_TIME = (Clock.currTime().toISOString.split('.'))[0];
    const string OUTPUT_FILENAME = "communch_" ~ SYS_TIME ~ ".csv";
    File output_file = File(OUTPUT_FILENAME, "w");

    int dist_count = 0;
    
    // fill the .csv file according to the task that has been performed
    switch (task_args[0]) {
        case "get_in_range":
            foreach (commune; results) {
                output_file.write(commune.real_name ~ "," ~
                                  to!dstring(distances[dist_count]) ~ "\n");
                dist_count++;
            }
            break;
        default:
            break;
    }
}

// get all communes in a given radius (in kilometers) from the starting point
void get_in_range(ref const string data, ref const string[] task_args, ref Commune[] communes)
{
    // -=-=-=- task evaluation step -=-=-=- //
    string  start = task_args[2],
            start_type =  "";
    int     range = to!int(task_args[3]);

    // aggregation type - only "all" supported as of now
    switch (task_args[1]) {
        case "all":
            break;
        default:
            writeln("Error: Argument 1 supplied to task " ~ task_args[0] ~ " wasen't understood or is missing.");
            stdc.exit(0);
            break;
    }

    // radius checking
    if (range <= 0) { 
        writeln("Error: Scanning range cannot be zero or a negative number.");
        stdc.exit(0);
    } else if (range > 40000) {
        writeln("Error: Scanning range cannot be higher than the Earth's circumference.");
        stdc.exit(0);
    }

    // is it an INSEE commune code? (int, any combination of 5 digits)
    auto r_insee_code = regex.regex(r"^[0-9]{5}$", "m");
    // is it a vector of coordinates? (floats, 0-180, up to 16-digit precision)
    // format: XX.XXX,XX.XXX
    // TODO: truncate coordinates to this fp number precision before testing
    auto r_deg_coords = regex.regex(r"^[0-9]{1,3}\.[0-9]{1,15},[0-9]{1,15}\.[0-9]{1,7}$", "m");
    // starting point
    try {
        if      (regex.matchAll(start, r_insee_code)) { start_type = "insee_code"; }
        else if (regex.matchAll(start, r_deg_coords)) { start_type = "deg_coords"; }
        else {
            writeln("Error: Argument 2 supplied to task " ~
            task_args[0] ~
            " is not an INSEE commune code nor a pair of coordinates in degrees.");
        }
    }
    catch (exception.RangeError) {
        writeln("Error: No argument 2 supplied to task " ~ task_args[0] ~ ".");
        stdc.exit(0);
    }

    // -=-=-=- task evaluation done -=-=-=- //

    // init communes list after the task check
    fetch_communes(data, communes);

    // prior conversion - only degrees coords. are fed to the task functions
    if (start_type == "insee_code") {
        writeln("Looking for communes around the one with INSEE code " ~ start ~ "...");
        insee_to_deg_coords(start, communes);
    }
    writeln("Starting coordinates: " ~ start ~ "\n" ~
            "Scanning in a " ~ to!string(range) ~ "km radius...");

    double lon1 = to!double(start.split(",")[0]);
    double lat1 = to!double(start.split(",")[1]);
    
    Commune[] results;
    double distance;
    double[] distances;
    foreach (commune; communes) {
        // distance is in kilometers - haversine() returns meters
        distance = (math.round(haversine(lat1, lon1, commune.lat_deg, commune.lon_deg, false) / 1000));
        if (distance <= range) {
            results ~= commune;
            distances ~= distance;
        }
    }

    writeln("Found " ~ to!string(results.length) ~ " communes with matching criteria.");

    write_output(task_args, results, distances);
}

void main(string[] args)
{
    // TODO: support multiple tasks in one run
    string data = "data.csv", task = "";
    getopt(
        args,
        "file", &data,
        "task", &task
    );

    Commune[] communes;
    const string[] task_args = task.split(":");
    // Evaluate first part of task
    switch (task_args[0]) {
        case "get_in_range":
            get_in_range(data, task_args, communes);
            break;
        case "":
            writeln("Please specify a task (--task <instructions>).\n" ~
                    "See readme for more info.");
            stdc.exit(0);
            break;
        default:
            writeln("Provided task was not understood.\n" ~
                    "See readme for more info.");
            stdc.exit(0);
            break;
    }
}

unittest {
    writeln("Haversine function test:");
    double result = haversine(48.86, 2.34445, 43.2967, 5.37639, false);
    // let's assume that fifty metres is an acceptable margin of error
    assert((result > 661173) || (result < 661223));
    writeln("Paris: lat deg. 48.86, lon deg. 2.34445\n" ~
            "Marseille: lat deg. 43.2967, lon deg. 5.37639\n" ~
            "Distance between the two cities:\n " ~
            to!string(result) ~ " metres");
}