# Communch - data set

This file contains various data about French towns and cities (communes).
Individual records in data.csv are organized as follows:

1)  commune id
2)  departement number:
    two digits for mainland France,
    one digit + one letter for Corsica,
    three digits for overseas territories
3)  slug, with spaces replaced by dashes, followed by the departement number if
    the commune has the same name as one or several other French towns
4)  slug in full caps
5)  simplified name - only lowercase letters and spaces, no accents
6)  real name
7)  soundex name
8)  metaphone name
9)  postcode - always five digits; when a city has several postcodes, they are
    chained together in a single string with dashes
10) three-digit commune number - when prefixed with the department number,
    yields the full five-digit INSEE code
11) five-digit INSEE code
12) the commune's arrondissement
13) the commune's canton
14) unknown
15) approx. population in 2010
16) approx. population in 1999
17) approx. population in 2012
18) approx. population density in 2010 - inhab. per sq. km
19) land area in 2014 - sq. km
20) latitude - degrees
21) longitude - degrees
22) latitude - gradients
23) longitude - gradients
24) latitude - decimal degrees
25) longitude - decimal degrees
26) min. elevation - metres
27) max. elevation - meters