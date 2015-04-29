#!/usr/bin/perl 

### constants 
$filein = "user.h"; 
$fileout= "NIF_bindings.h"; 
$mapper = "mapper.erl";


open IN, "<$filein"         or die "Cannot open file $filein  for reading\n";
open OUT,">$fileout"        or die "Cannot open file $fileout for writing\n";

$skeleton_n = 0; 
@skelsunary = ();
@skelsbinary = (); 

while($line = <IN>)  {
    if($line =~ /ERL_GPU_([A-Z]*)(.*),([a-zA-Z_1-9\.]*)/) {
	$kind = $1; 
	$name = $3; 
	### print "Processing $kind : $name\n";
	$skeleton_n++;
	if($kind eq "MAPZIP") {
	    # binary skeleton
	    print OUT "\{\"$name\",2,$name\},\n";
	    push(@skelsbinary,$name); 
	} else {
	    # unary
	    print OUT "\{\"$name\",1,$name\},\n";
	    push(@skelsunary, $name); 
	}
    }
}
close OUT; 
close IN;
### print "UNARY @skelsunary\n";
### print "BINARY @skelsbinary\n";
open ERL,">$mapper"         or die "Cannot open file $mapper  for writing\n";
print ERL "-module(mapper).\n-on_load(init/0).\n\n-export([\n\tinit/0,\n";
foreach $u (@skelsunary) {
    print ERL "\t$u/1,\n";
}
foreach $b (@skelsbinary) {
    print ERL "\t$b/2,\n";
}
print ERL "\tskeletonlib/1]).\n";
print ERL "init()->\n\terlang:load_nif(\"./mapper\",0).\n\n";

foreach $u (@skelsunary) {
    print ERL "$u(_)->\"NIF lib not loaded\".\n";
}
foreach $b (@skelsbinary) {
    print ERL "$b(_,_)->\"NIF lib not loaded\".\n";
}
print ERL "skeletonlib(_)->\"NIF lib not loaded\".\n";
close ERL; 
exit;


