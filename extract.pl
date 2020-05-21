use strict;
use utf8;
use CAM::PDF;
use CAM::PDF::PageText;
use Data::Dumper;
use JSON;

my @filenames = (
	"2020_04_22.pdf", 
	"2019_06_21.pdf", 
	"2019_05_22.pdf"
);
my @expenses;
foreach my $filename (@filenames){
	undef @expenses ; # clean file
	my $pages = get_number_of_pages($filename);
	print "There are $pages pages\n";
	if ($pages eq 1){
		get_first_page(get_string_from_pdf_file($filename, 1));
	}else{
		get_first_page(get_string_from_pdf_file($filename, 1));
		if ($pages gt 2){
			foreach my $page_num (2..$pages-1){
				get_mid_page(get_string_from_pdf_file($filename, $page_num));
			}
		}
		get_last_page(get_string_from_pdf_file($filename, $pages));
	}
	save_results($filename, {data =>\@expenses});
	print Dumper(\@expenses);
	
}


sub get_number_of_pages {
	
	my ($filename) = @_;
	
	return CAM::PDF->new($filename)->numPages();
}

sub get_last_page{

	my ($pdf_string) = @_;
	my ($intro, $row_data) = split /Übertrag von Seite\s+\d\s+\+\s(?:\d+\.)?\d{1,3},\d{2}\s/, $pdf_string;
	# print "$pdf_string\n";
	my ($data, $trailing) = split /(?:\d+\.)?\d{1,3},\d{2}\+ Neuer Saldo/, $row_data;
	$data =~ s/\n//g;
	my @entries = split /\s-\s|\s\+\s/, $data;

	foreach my $entry (@entries){
		# print $entry . "\n";
		my ($name, $expense, $date_made, $date_paid) = ($1, $2, $3, $4) if ($entry =~ m/^(.+)\s((?:\d+\.)?\d{1,3},\d{2})\s(\d{2}\.\d{2}\.\d{2})\s(\d{2}\.\d{2}\.\d{2})$/);
		next if (skip_entry($name) or !defined($name));
		my %expense = (
			'name' => $name,
			'price' => $expense,
			'date_created' => $date_made,
			'date_paid' => $date_paid,
		);
		push @expenses, \%expense;
	}		
}

sub get_mid_page{

	my ($pdf_string) = @_;
	
	my ($intro, $row_data) = split /Übertrag von Seite\s+\d\s+\+\s(?:\d+\.)?\d{1,3},\d{2}\s/, $pdf_string;
	my ($data, $trailing) = split / - Zwischensumme/, $row_data;
	$data =~ s/\n//g;
	my @entries = split /\s-\s|\s\+\s/, $data;

	foreach my $entry (@entries){
		# print $entry . "\n";
		my ($name, $expense, $date_made, $date_paid) = ($1, $2, $3, $4) if ($entry =~ m/^(.+)\s((?:\d+\.)?\d{1,3},\d{2})\s(\d{2}\.\d{2}\.\d{2})\s(\d{2}\.\d{2}\.\d{2})$/);
		next if (skip_entry($name) or !defined($name));
		my %expense = (
			'name' => $name,
			'price' => $expense,
			'date_created' => $date_made,
			'date_paid' => $date_paid,
		);
		push @expenses, \%expense;
	}		
}


sub get_first_page{

	my ($pdf_string) = @_;
	
	my ($intro, $row_data) = split /Abrechnung \d{2}\.\d{2}\.\d{2}\s\+\s(?:\d\.)?\d{3},\d{2}\s/, $pdf_string;
	my ($data, $trailing) = split /Zwischensumme/, $row_data;
	$data =~ s/\n//g;
	my @entries = split /\s-\s|\s\+\s/, $data;

	foreach my $entry (@entries){
		# print $entry . "\n";
		my ($name, $expense, $date_made, $date_paid) = ($1, $2, $3, $4) if ($entry =~ m/^(.+)\s((?:\d+\.)?\d{1,3},\d{2})\s(\d{2}\.\d{2}\.\d{2})\s(\d{2}\.\d{2}\.\d{2})$/);
		next if (skip_entry($name) or !defined($name));
		my %expense = (
			'name' => $name,
			'price' => $expense,
			'date_created' => $date_made,
			'date_paid' => $date_paid,
		);
		push @expenses, \%expense;
	}		
}

sub get_string_from_pdf_file() {
		
	my ($filename, $page) = @_;
	
	my $pdf = CAM::PDF->new($filename);
	my $pageone_tree = $pdf->getPageContentTree($page);
	
	return CAM::PDF::PageText->render($pageone_tree);
}

sub skip_entry {
	
	my ($name) = @_;
	my @words_to_skip = (
		"Einzahlung", # transfer from bank
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


sub save_results {
	
	my ($file, $expenses_ref) = @_;
	
	$file =~ s/.pdf//g;
	my $filename = ".\\json\\$file.json";

	open(FH, '>', $filename) or die $!;
	print FH to_json($expenses_ref);
	close(FH);

	print "Written to $filename successfully!\n";
}
