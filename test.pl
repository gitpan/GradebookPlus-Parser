# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 4, onfail => sub { warn "\ntest failed\n" } };
use GradebookPlus::Parser;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
my $data = q|
                                Carlmont School
                         Kingsfield's Per 7 Government
                        Gradebook as of Fri Jan 4, 2002

Name                      1   2   3  4   5   6  7     Total    Pct. 
--------------------------------------------------------------------
Adams, John              10  10  13  9  76  30  3       151    82.5 
Adams, Quincy            10  10  12  9  67  30  3       141    77.0 
Cleveland, Grover        10  10  11 10  68  30  3       142    77.6
Coolidge, Cal            10  10  14 10  82  30  3       159    86.9
Eisenhower, Dwight       10  10  15 10  93  30  3       171    93.4
Fillmore, Millard        10  10  16 10 100  30  3       179    97.8
Ford, Jerry              10  10  19 ( ) 93  30  3       165    90.2
Grant, U. S.             10  10  18 10  68  30  3       149    81.4
Harding, Warren          10  10  17 10  73  30  3       153    83.6
Hoover, Herb             10  10  20 10  92  30  3       175    95.6
Jackson, Andy            10  10  20 10  95  30  3       178    97.3
Jefferson, Tommy         10  10  19 10  78  30  3       160    87.4
Kennedy, Jack            10  10  16 10  72  30  3       151    82.5
Lincoln, Abe             10  10  18 10  75  30  3       156    85.2
Madison, Jim              9  10  14 10  80  30  3       156    85.2
McKinley, Bill          ( )  10  12 10  70  30  3       135    73.8
Monroe, John             10  10  16  5  93  30  3       167    91.3
Pierce, Frank             9  10  18  8  83  30  3       161    88.0
Polk, James               9  10  15  9  68  30  3       144    78.7
Roosevelt, Frankie       10  10  19 10  73  30  3       155    84.7
Roosevelt, Teddy         10  10  17 10  72  30  3       152    83.1
Truman, Harry            10  10  17 10  77  30  3       157    85.8
Tyler, John              10  10  10  9  88  30  3       160    90.9
Washington, George      ( )  10  14 10  79  30  3       146    79.8
Wilson, Woody            10  10  17 10  72  30  3       152    83.1

Average :                 9  10  16 19 79.5 30  3     155.4    85.7
Possible :               10  10  20 10 100  30  3       183

"( )"  Indicates the assignment was not submitted.


Key :
1) HW 9-11                             5) TEST- Chap 1
2) HW 9-12                             6) test
3) QUIZ                                7) next
4) HW 9-14




                                Carlmont School
                         Kingsfield's Per 7 Government
                        Gradebook as of Fri Jan 4, 2002

Name                            Grade    Cat 1     Cat 2     Cat 3
------------------------------------------------------------------
Adams, John                       B       81.5      96.7      69.6
Adams, Quincy                     C       74.6      96.7      65.2
Cleveland, Grover                 C       75.4     100.0      60.9
Coolidge, Cal                     B       86.2     100.0      73.9
Eisenhower, Dwight                A       94.6     100.0      78.3
Fillmore, Millard                 A      100.0     100.0      82.6
Ford, Jerry                       A       94.6      66.7      95.7
Grant, U. S.                      B       75.4     100.0      91.3
Harding, Warren                   B       79.2     100.0      87.0
Hoover, Herb                      A       93.8     100.0     100.0
Jackson, Andy                     A       96.2     100.0     100.0
Jefferson, Tommy                  B       83.1     100.0      95.7
Kennedy, Jack                     B       78.5     100.0      82.6
Lincoln, Abe                      B       80.8     100.0      91.3
Madison, Jim                      B       84.6      96.7      73.9
McKinley, Bill                    C       76.9      66.7      65.2
Monroe, John                      A       94.6      83.3      82.6
Pierce, Frank                     B       86.9      90.0      91.3
Polk, James                       C       75.4      93.3      78.3
Roosevelt, Frankie                B       79.2     100.0      95.7
Roosevelt, Teddy                  B       78.5     100.0      87.0
Truman, Harry                     B       82.3     100.0      87.0
Tyler, John                       A       90.8      90.0     100.0
Washington, George                C       83.8      66.7      73.9
Wilson, Woody                     B       78.5     100.0      87.0

Average :                     84.2      93.9      83.8
Possible :                      60        20        20

"( )"  Indicates the assignment was not submitted.

Category Key : 
1) TEST     2) HW        3) OTHER
|;
my $gradebook = new GradebookPlus::Parser;
ok(2);
$gradebook->parse($data);
ok(3);
$gradebook->assignment_names;
ok(4);