use strict;
use warnings;
use feature 'say';
use Data::Dumper;

# use DateTime;

use File::Slurp;

use JSON qw( );
my $filename = 'registro.json';
my $registro_text = do {
   open(my $json_fh, "<:encoding(UTF-8)", $filename)
	  or die("Can't open \$filename\": $!\n");
   local $/;
   <$json_fh>
};

# Inventario (items disponibles) ###
my @inventario =  split /\W/, read_file('inventario');

# Pedidos (input) ##################
my @pedidos = read_file('pedidos.csv');

# Registro (almacen de reservas) ###
my $json = JSON->new;
my $registroJson = $json->decode($registro_text); # Cambiar nombre Registro

my %registros = %$registroJson;


informeReservas();

foreach (@pedidos){
	# chomp;
	if( $_ =~ /^\s*item,mes,/ ){ # borrrar primera linea
		next;
	}
	consultar($_);
}

informeReservas();

# Subs
sub consultar{
	my ($item,$mes,$dia,$hora,$duracion) =  split /\W/, $_;

	my $pedidoItem = {
		# item =>		$item,
		mes => $mes,
		dia => $dia,
		hora => $hora,
		duracion => $duracion
	};


	header($item);

	if($item ~~ @inventario){ # en inventario?
		say "Ingresando pedido: $item $mes $dia $hora $duracion";

		if($registros{$item}){
			my @reservasItem = @{$registros{$item}{reservas}}; # copy
			my $nReservasItem = scalar @reservasItem;
			say "| Existen $nReservasItem reservas registrdas para: $item";

			# MAtriz de reservas que tiene hasta el momento el item
			# Es mejor guardar e esta manera la info en registro para no repetir
			# YA VA DECANTAR CUANDO GRABE ESTOS REGISTROS

			my %matrizHoraria = (); # {$mese}{$dia}$hora} = $duracion
			for (@matrizHoraria){
				my $l = $_->{duracion};
				my $h = $_->{hora};
				my $d = $_->{dia};
				my $m = $_->{mes};
				$matrizHoraria{$m}{$d}{$h} = $l;
			}



		}else{
			say "| No se encontraron reservas para: $item";
			$registros{$item} = {"reservas" => [$pedidoItem]};
			say "Creo primer registro para este item,\ncontinuo."; next;
		}

	}else{
		say "\nNo existe: $item en el inventario ###";
	}

}




# Subrutinas
sub reservarPedido {

	my $p = $_[-1];
	push $_[0], $p;

	# Y si calculo la duracion aca?

	# cuando los pedidos lleguen con la duracion chequeada vamos a
	# poder hacer algo como esto: REVISAR RECURCION

	# for ($i = 0, $i < $p{duracion}, $i++){
	# 	my $pedidoHijo = {
	# 		# item =>$item,
	# 		mes => $mes,
	# 		dia => $dia,
	# 		hora => $hora,
	# 		duracion => $duracion-$i,
	# 	};
	# reservarPedido($registros{$item}{reservas}, $pedidoHijo);
	# }


	# mostrar esto en la matriz para ver que estebien
	print "+ Agregue la reserva: ";
	print_hash($_[0][-1]);

}

# Informe de pedidos entrantes
sub informePedido {
	header('Informe de Pedidos');

	# foreach my $key ( sort keys %registros ){
	# 	my $cuantasReservas = scalar @{$registros{$key}{reservas}};
	# 	say "Item: $key -> $cuantasReservas reservas";
	# }

}

sub informeReservas {
	header('Informe de Registros');

	foreach my $key ( sort keys %registros ){
		my $cuantasReservas = scalar @{$registros{$key}{reservas}};
		say "Item: $key -> $cuantasReservas reservas";
	}

}

sub print_hash {
	my $href = shift;
	print "$_:$href->{$_} " for keys %{$href};
	print "\n";
}

sub header {
	print "\n";
	my $s = shift;
	my $l = length $s;
	my $dif = 26 - $l;
	print "### ";
	print $s;
	print " ";
	print "#"x$dif;
	print "\n";
}