package GradebookPlus::Parser;

use 5.006;
use strict;
use warnings;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.


our $VERSION = '0.08';
sub new
{
    my $proto = shift;

    my $self      = {};
    my $class     = ref($proto) || $proto;
    $self->{index} = 0;

    bless ($self, $class);
}

sub parse
{
    my ($self, $dump) = @_;
    chomp $dump;
    $dump = reverse $dump;
    chomp $dump;
    $dump = reverse $dump;
    my @dump = split (/\n/, $dump);

# determine the amount of sections in the script.  In a 1 pager, it will be 3, 2 pages will be 5, 3 will be 7...
    my @sections;
    my $q=0;
    foreach my $line (@dump)
    {
        if ($line =~ /^\-+/i)
    {
        $q++;
        next;
    }
        $sections[$q] .= $line."\n";
        $q++ if ($line =~ /^Possible :/i);
    }
    $q = ($q/2);

# get the title
    chomp (@dump);
    my $firstline = 0;

    do { $firstline = shift @dump } while ( $firstline !~ /[a-z]+/ );

    $self->{name} = $firstline."\n".(shift @dump)."\n".(shift @dump);
    shift @dump;

# the length of the longest possible record
    my @fields = split (/\s+/, shift @dump);
    shift @dump;
    my ($length) = $dump[0] =~ /^(.*?\s.*?\s+)[^\s]/;
    $length      = length($length)-3;

# grabs the records out of the sections
    my @names;
    my @student_info;
    for (my $i=1; $i<@sections; $i+=2)
    {
        push @student_info, join("\n",grep{$_}map{
                                          my $l = ($length<length($_))?$length:length($_);
                                          push(@names,substr($_,0,$l));
                                          $_=substr($_,$l,length($_)-$l)
                                         }
                                      split(/\n/,$sections[$i]));
        delete $sections[$i];
    }

# remove duplicate names
    @names = do{my%h;grep{!$h{$_}++}@names};

# concatrate records spanning multiple pages.
    my @temp_students = @student_info;
    @student_info = ();
    foreach my $temp (@temp_students)
    {
        my @temp = split(/\n/, $temp);
        for (my $i=0; $i<@temp; $i++)
        {
             $student_info[$i] .= $temp[$i];
        }
    }
@student_info = grep{$_}@student_info;
@names = grep{$_}@names;
# reappend name back to record
    for (my $i=0; $i<@names; $i++)
    {
        $student_info[$i] = $names[$i].$student_info[$i];
    }

# remove deleted sections
    @sections = grep{$_}@sections;

# concatrate field headings spanning multiple pages
    for (my $i=1; $i<(@sections-1); $i++)
    {
        my @entry = split (/\n/, $sections[$i]);
        my @temp = (split /\s+/, $entry[$#entry]);
        push (@fields, @temp);
    }
    $q=0;
    for (0..$#fields)
    {
        delete $fields[$_] if (($fields[$_] =~ /name/i) && $q);
        next if !$fields[$_];
        $q++ if ($fields[$_] =~ /name/i);
    }

# remove empty fields and strip illegal characters
    @fields = grep{$_}@fields;

# count number of assignments
    my $noa = -1;
    for (my $i=1; $i < @fields; $i++)
    {   last unless ($fields[$i] =~ /^\d+$/);
        $noa++;
    }

    my $student = {};
    my @order = ();
    my $loc = 0;
    my $empty = 0;

# parse records
    foreach my $dump (@student_info)
    {
        $loc++;
        chomp $dump;
        last if ($dump eq '');
        last if ($dump eq "\n");
        last if ($dump eq "\r");
        last if ($dump eq "\r\n");
        last if ($dump eq "\n\r");
        last if ($dump =~ /average/i);
        last if ($dump =~ /:/);
        my ($name, $rest) = ($dump =~ /(.*?)(\d.*)/) or last;
        my @data = split(/\s+/, $rest);

        my @data1     = split (/\,/, $name);
        my $lastname  = shift @data1;
        my $firstname = shift @data1;
        ($firstname)  = $firstname =~ m/^\s*(.*?)\s*$/;
        ($lastname)   = $lastname  =~ m/^\s*(.*?)\s*$/;

        last if (lc($lastname) !~ /[a-z?]/);

        $name = $firstname."_".$lastname;
        push (@order, $name);

        # assignments

        my %assignments;
        my $data = join ' ', @data;
    $empty++ if ($data =~ s/(\(\s+\))/ () /g);
    $data =~ s/(ex)/0/g;
    @data = split(/\s+/, $data);

        for my $i (0 .. $noa)
        {
            my $entry = shift @data;
            $assignments{$fields[$i+1]} = $entry;
        }

        my $total   = shift @data;
        my $percent = shift @data;
        my $grade   = shift @data;

        my %catagories;
        my $count = 1;
        foreach my $entry (@data)
        {
            $catagories{$count} = $entry;
            $count++;
        }

        my $password = crypt ($lastname, $firstname);
        $password = ( length($password) > 6 ) ? substr($password, 0, 6) : $password;
        $password =~ tr/.,!@#$%^&*(){}[]/q/;

        $student->{$name} = {
                             firstname  => $firstname,
                             lastname   => $lastname,
                             password   => $password,
                             grade      => $grade,
                             total      => $total,
                             percent    => $percent,
                             assignment => {%assignments},
                             catagory   => {%catagories},
                            }
    }
    my @info = @student_info[$loc-1 .. $#student_info];

    my @averages = split (/\s+/, shift @info);
        shift @averages;
        shift @averages;
        my %a_averages = ();

        for my $i (0 .. $noa)
        {
            my $average = shift @averages;
            $a_averages{$i+1} = $average;
        }

        my $total_average = shift @averages;
        my $pct_average   = shift @averages;
        my %c_averages = ();

        for my $i (0..@averages)
        {
            $c_averages{$i+1} = $averages[$i];
        }

        my %averages = (
                        assignment => {%a_averages},
                        catagory   => {%c_averages},
                       );

    my @possible = split (/\s+/, shift @info);
        shift @possible;
        shift @possible;
        my %a_possible = ();
        for my $i (0 .. $noa)
        {
            my $possible = shift @possible;
            $a_possible{$i+1} = $possible;
        }

        my $total_possible = shift @possible;
        my %c_possible = ();

        for my $i (0..@possible)
        {
            $c_possible{$i+1} = $possible[$i];
        }

        my %possible = (
                        assignment => {%a_possible},
                        catagory   => {%c_possible},
                       );

     my @detailed;
     foreach my $section (@sections)
     {
         $section  .= $firstline;
         ($section) = $section =~ /^(.*?)\Q$firstline\E/si;
     }

     @info = ();
     foreach my $section (@sections)
     {
         my @entry = split (/\n/, $section);
         push (@info, @entry);
     }

     @info = grep{$_}@info;
     @info = do{my%h;grep{!$h{$_}++}@info};
     @info = grep{$_ !~ /\Q"( )"  Indicates the assignment was not submitted.\E/i}@info;
     @info = grep{$_ !~ /\Q"ex"   Indicates student exempted from entry.\E/i}@info;


     $noa++;
     my @asses;

     shift @info;
     # shift @info;

     while (my $entry = shift @info)
     {
         chomp $entry;
         last if ($entry eq '');
         last if ($entry eq "\n");
         last if ($entry eq "\r");
         last if ($entry eq "\r\n");
         last if ($entry eq "\n\r");
         last if ($entry =~ /^Category/i);
         $entry =~ s/(\d+\))/  $1/g;
         $entry =~ tr/(/{/;
         $entry =~ s/(?:(\{[^)]*)(?<!\d)(\)*))/$1} /gi;
         $entry =~ s/\s*\}/} /g;
         my @row = grep{$_}
         map{
             tr/\n\r//d;
             s/(.*?)\s*$/$1/;
             tr/ /_/;
             s/_//;
             s/_// if(/^\d+\)_/);
             $_
            }

         split(/\s{2,}/, $entry);
         push (@asses, @row);
     }

     my %a_names;
     foreach my $entry (@asses)
     {
         chomp $entry;
         my @a_names = split(/\)/, $entry);
         $a_names[1] =~ s/[^\w\d]//g;

         $a_names{$a_names[0]} = $a_names[1];
     }

     my @assignment_names = @fields[1 .. $noa];
     foreach my $assignment (@assignment_names)
     {
         $assignment = $a_names{$assignment};
     }

     #shift @info;

     my @catagory_names;
     #my @catagories = split (/\s+/, shift @info);


     #for (my $i=1; $i<@catagories; $i+=2)
     #{
     #    push (@catagory_names, $catagories[$i+1]);
     #}

     $self->{student}        = $student;
     $self->{average}        = {%averages};
     $self->{assignment}     = [@assignment_names];
     $self->{catagory}       = [@catagory_names];
     $self->{order}          = [@order];
     $self->{possible}       = {%possible};
     $self->{class_average}  = $pct_average;
     $self->{total_average}  = $total_average;
     $self->{total_possible} = $total_possible;
}

sub report_name
{
     my $self = shift;
     return (join "\n", map {s/\s{2,}//; $_} split (/\n/, $self->{name}));
}

sub list_students
{
    my $self = shift;
    my @return_array;
    foreach my $name (keys(%{$self->{student}}))
    {
        my $lastname  = $self->{student}->{$name}->{lastname};
        my $firstname = $self->{student}->{$name}->{firstname};
        my $password  = $self->{student}->{$name}->{password};
        push (@return_array, {first=>$firstname, last=>$lastname, pw=>$password});
    }
    return @return_array;
}

sub next_student
{
    my $self = shift;
    my $returnv =  ${$self->{order}}[$self->{index}];
    $self->{index}++;
    $self->{index} = 0 if ($self->{index} > $#{$self->{order}});
    return $returnv;
}

sub average_percent
{
    my $self = shift;
    return $self->{class_average};
}

sub average_points
{
    my $self = shift;
    return $self->{total_average};
}

sub possible_points
{
    my $self = shift;
    return $self->{total_possible};
}

sub assignment_names
{
    my $self = shift;
    return @{$self->{assignment}}
}

sub assignment_possible
{
    my ($self, $name) = @_;
    my $index = get_index($name, @{$self->{assignment}});
    return $self->{possible}->{assignment}->{$index};
}

sub assignment_scores
{
    my ($self, $name) = @_;
    my @return_array;

    my $index = get_index ($name, @{$self->{assignment}});
    foreach my $student (@{$self->{order}})
    {
        my $score = $self->{student}->{$student}->{assignment}->{$index};
        push (@return_array, $score);
    }
    return @return_array;
}

sub assignment_average
{
    my ($self, $name) = @_;
    my $index = get_index($name, @{$self->{assignment}});
    return $self->{average}->{assignment}->{$index};
}

sub catagory_names
{
    my $self = shift;
    return @{$self->{catagory}}
}

sub catagory_possible
{
    my ($self, $name) = @_;
    my $index = get_index ($name, @{$self->{catagory}});
    return $self->{possible}->{catagory}->{$index};
}

sub catagory_scores
{
    my ($self, $name) = @_;
    my @return_array;

    my $index = get_index ($name, @{$self->{catagory}});
    foreach my $student (@{$self->{order}})
    {
        my $score = $self->{student}->{$student}->{catagory}->{$index};
        push (@return_array, $score);
    }
    return @return_array;
}

sub catagory_average
{
    my ($self, $name) = @_;
    my $index = get_index($name, @{$self->{catagory}});
    return $self->{average}->{catagory}->{$index};
}

sub student_assignments
{
    my ($self, $first, $last) = @_;
    my $student = $first."_".$last;
    my @return_value;
    my @keys;

    while ( my($key,$value) = each(%{$self->{student}->{$student}->{assignment}}) )
    {
        push (@keys, $key);
        push (@return_value, $value);
    }

    my @order;
    foreach my $assignment (@{$self->{assignment}})
    {
        for (my $i=0; $i<@keys; $i++)
        {
            my $index = get_index($assignment, @{$self->{assignment}});
            push (@order, $i) if ($index == $keys[$i]);
        }
    }

    @return_value = @return_value[@order];
    return @return_value;
}

sub student_catagories
{
    my ($self, $first, $last) = @_;
    my $student = $first."_".$last;
    my @return_value;
    my @keys;

    while ( my($key,$value) = each (%{$self->{student}->{$student}->{catagory}}) )
    {
        push (@keys, $key);
        push (@return_value, $value);
    }

    my @order;
    foreach my $catagory (@{$self->{catagory}})
    {
        for (my $i=0; $i<@keys; $i++)
        {
            my $index = get_index($catagory, @{$self->{assignment}});
            push (@order, $i) if ($index == $keys[$i]);
        }
    }

    @return_value = @return_value[@order];
    return @return_value;
}

sub student_total_points
{
    my ($self, $first, $last) = @_;
    my $student = $first."_".$last;

    return $self->{student}->{$student}->{total};
}

sub student_percent
{
    my ($self, $first, $last) = @_;
    my $student = $first."_".$last;

    return $self->{student}->{$student}->{percent};
}

sub student_letter
{
    my ($self, $first, $last) = @_;
    my $student = $first."_".$last;
    return $self->{student}->{$student}->{grade};
}

# subroutines for use by the module

sub get_index
{
    my ($name, @fields) = @_;
    for (my $i=0; $i<@fields; $i++)
    {
        if ($fields[$i] eq $name)
        {
            return $i+1;
        }
    }
}

"JAPH";

=pod

=head1 NAME

GradebookPlus::Parser

=head1 ABASTRCT

Parses Gradebook Plus text reports.

=head1 SYNOPSIS
=begin html
<pre>
use GradebookPlus::Parser;

# create a new gradbook
my $gradebook = new GradebookPlus::Parser;

# parse
$gradebook->parse($data);

# do stuff with the methods
</pre>
=end html
=head1 DESCRIPTION

Gradebook is a module useful for parsing Gradebook Plus text reports, 
a program used by many K-12 school districts.  Simply go to 
=begin html
<pre>
Reports->
Gradebook of entire Class->(check fancy report, catagory totals, and all grades)->
Save to disk.
</pre>
=end html
The parser can then parse the contents of this file.
Use it how you like; I use it so teachers can put their grades
online with minimal effort on their part.   

=head1 METHODS

=over 4

=item parse($report)

Send it a scalar with the report to parse, in one large chunk.  The object
becomes filled upon using this method.  You can access the data using the below methods:

=item report_name

Returns the name of the report, if you happen want it.

=item list_students

Returns a list of students in the report.  Each element
is a reference to an anonymous hash with 3 elements:
=begin html
<pre>
first
last
pw
</pre>
=end html
pw is a generated password which you can use, rather than
create your own.  Remember, this module was developed for
use with an online grade report system.

=item next_student

A counter of the next student in the report.
Kinda like an internal foreach loop.
Returns the next student.

=item average_percent

Returns average total percent for the class

=item average_points

Returns average total points for the class

=item total_points

Returns total possible points for the class

=item assignment_*($assignment_name)

Returns * for the given assignment name  The exception is
assignment_names, which does not take an argument and returns
a list of all assignment names.
=begin html
<pre>
List of methods:
assignment_names
assignment_possible
assignment_scores
assignment_average
</pre>
=end html

=item catagory_*($catagory_name)

Returns * for the given catagory name  The exception is
catagory_names, which does not take an argument and returns
a list of all catagory names.
=begin html
<pre>
List of methods:
catagory_names
catagory_possible
catagory_scores
catagory_average
</pre>
=end html
=item student_*($first, $last)

Returns * for the given student.  The exceptions are with
student_assignments and student_catagories, which return an
array of all scores in the same order as @assignment_names.
=begin html
<pre>
List of methods:
student_assignments
student_catagories
student_total_points
student_percent
student_letter
</pre>
=end html
=head1 AUTHOR

Joseph F. Ryan, ryan.311@osu.edu

=cut