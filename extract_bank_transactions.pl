use strict;
use utf8;
use open qw/ :std :encoding(utf-8) /;

use Data::Dumper;
use JSON;
use Text::CSV;

my $debug = 0;

my $src = "bank_transactions"; # Folder where all your pdfs are
my $converted = "csv_transactions"; # Folder where pdfs will be converted to csv

# Transform pdf to csv
system("python pdf_to_csv_with_tabula_movements.py $src $converted");
print "PDF to CSV done\n";


print "Processing data...\n";
my @expenses;
my $year;
my @files = glob( $converted . '/*.csv' );
my $csv = Text::CSV->new({ sep_char => ',' });
foreach my $filename (@files){
	print "Processing $filename\n";
	$year = $1 if ($filename =~ m/_Nr_(\d{4})_/);
	undef @expenses; # remove data from previos interaction
	open(my $data, '<', $filename) or die "Could not open '$filename' $!\n";
	while (my $line = <$data>) {
		chomp $line;
		print $line."\n" if ($debug);
		if ($csv->parse($line)) {
			my @fields = $csv->fields();
			my %expense;
			if (scalar(@fields) eq 6){
				my ($date, $name,$dum1,$dum2,$dum3,$transaction) = @fields;
				save_entry($date, $name, $transaction);
			}elsif(scalar(@fields) eq 5){
				my ($date, $name,$dum1,$transaction, $transaction_2) = @fields;

				if (!($name =~ m/[a-z]/gi)){
					my ($date_1, $date_2, $name_1,$transaction_1, $transaction_1_2) = @fields;
					save_entry("$date_1 $date_2", $name_1, $transaction_1, $transaction_1_2);

				}else{
					save_entry($date, $name, $transaction, $transaction_2);
				}
			}else{
				print "Invalid line $line\n";
			}
			
		}else {
			warn "Line could not be parsed: $line\n";
		}
	}
	filter_transactions();
	
	save_results($filename, {data =>\@expenses});
	print Dumper(	\@expenses);

}

sub filter_transactions {

	my @words_to_skip = (
		"KREDITKARTENABRECHNUNG", # transfer from self
		"DKB VISACARD", # transfer from self
	);

	foreach my $word (@words_to_skip){
		@expenses = grep { ! ($_->{"name"} =~ m/\Q$word/)} @expenses;
	}
	
	@expenses = grep { ! ($_->{"amount"} eq "0,00") } @expenses;

	
}


=head1 save_entry

=head1 Stores an entry in the global array of expenses

=cut
sub save_entry {
	
	my ($date, $name, $transaction, $transaction_2) = @_;
	
	my $amount = (defined($transaction_2) and $transaction_2 ne "") ? $transaction_2 : $transaction;
	my ($date_created, $date_paid) =  ($date =~ m/  (\d{2}\.\d{2}\.)  \s+  (\d{2}\.\d{2}\.)  /x) ? ($1.$year, $2.$year) : ("","");
	
	if ($date_created ne "" and $name ne "" and $amount ne "" ){
		
		my $type = get_type($name);		
		my %expense = (
			'name' => $name,
			'amount' => $amount,
			'type' => $type,
			'date_created' => $date_created,
			'date_paid' => $date_paid,
		);
		push @expenses, \%expense;
		
	}elsif( $date_created eq "" and $date_paid eq "" and $name ne "" and $transaction eq ""){ # Two line name 
		print "Apending $name" if ($debug);
		if (defined($expenses[scalar(@expenses)-1])){
			$expenses[scalar(@expenses)-1]->{'name'} .= " $name";
		}
	}
}

=head1 get_type

=head1 Checks for transactions names that are an income to the account

=cut

sub get_type {
	my ($name) = @_;
	my @words_to_skip = (
		"Zahlungseingang", # transfer from self
		# ""
	);

	foreach my $word (@words_to_skip){
		if ($name =~ m/\Q$word/){
			print "Income: $name\n" if ($debug);
			return "income" ;
		}
	}
	
	return "expense";
}



=head1 save_results

=head1 Stores the result in a json with the same name as the pdf

=cut

sub save_results {

	my ($file, $expenses_ref) = @_;
	
	$file =~ s/.csv//g;
	$file =~ s/.+\///g; #remove path
	my $filename = ".//json//$file.json";

	open(FH, '>', $filename) or die "Error saving $filename $!";
	print FH to_json($expenses_ref);
	close(FH);

	print "Written to $filename successfully!\n";
}
