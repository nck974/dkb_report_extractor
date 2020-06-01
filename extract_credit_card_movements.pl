use strict;
use utf8::all; 

use Data::Dumper;
use JSON;
use Text::CSV;

my $debug = 0;

my $src = "credit_card_movements"; # Folder where all your pdfs are
my $converted = "csv"; # Folder where pdfs will be converted to csv

# Transform pdf to csv
system("python pdf_to_csv_with_tabula_credit.py $src $converted");
print "PDF to CSV done\n";


print "Processing data...\n";
my @expenses;

my @files = glob( $converted . '/*.csv' );
my $csv = Text::CSV->new({ sep_char => ',' });
foreach my $filename (@files){
	print "Processing $filename\n";
	undef @expenses; # remove data from previos interaction
	open(my $data, '<:encoding(cp1252)', $filename) or die "Could not open '$filename' $!\n"; # tabula outputs ANSI
	while (my $line = <$data>) {
		chomp $line;
	 
		if ($csv->parse($line)) {
			my @fields = $csv->fields();
			my %expense;
			if (scalar(@fields) eq 4){
				
				my ($date_created, $date_paid, $name, $transaction) = @fields;
				save_entry($date_created, $date_paid, $name, $transaction);
			}elsif(scalar(@fields) eq 7){
				
				my ($date_created, $date_paid, $name,$currency, $price_in_currency, $conversion,  $transaction) = @fields;
				save_entry($date_created, $date_paid, $name, $transaction);
			}else{
				print "Invalid line $line\n";
			}
			
		}else {
			warn "Line could not be parsed: $line\n";
		}
	}
	
	save_results($filename, {data =>\@expenses});
	print Dumper(	\@expenses);

}

=head1 save_entry

=head1 Stores an entry in the global array of expenses

=cut
sub save_entry {
	
	my ($date_paid, $date_created, $name, $transaction) = @_;
	
	if ($date_paid ne "" and $name ne "" and $transaction ne ""){
		
		next if (skip_entry($name));

		my $type = ($transaction =~ m/-/) ? "expense" : ($transaction =~ m/\+/) ? "income" : undef;
		my $amount = $1 if ($transaction =~ m/(\d{1,6},\d{2})/) ;
		
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



=head1 skip_entry

=head1 Checks for transactions names that shall not be stored

=cut

sub skip_entry {
	
	my ($name) = @_;
	my @words_to_skip = (
		"Einzahlung", # transfer from bank
		"Ausgleich Kreditkarte", # transfer from bank
		"Saldo letzte Abrechnung",
		"Erste Bank, Wien", # cash
		# ""
	);

	foreach my $word (@words_to_skip){
		if ($name =~ m/\Q$word/){
			print "Skipping $name\n";
			return 1 ;
		}
	}
	
	return 0;
}


=head1 save_results

=head1 Stores the result in a json with the same name as the pdf

=cut

sub save_results {
	# TODO make this look nicer
	my ($file, $expenses_ref) = @_;
	
	$file =~ s/.csv//g;
	$file =~ s/.+\///g; #remove path
	my $filename = ".//json//$file.json";

	open(FH, '>', $filename) or die "Error saving $filename $!";
	print FH to_json($expenses_ref);
	close(FH);

	print "Written to $filename successfully!\n";
}
