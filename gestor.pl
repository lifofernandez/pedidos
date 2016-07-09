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


imprimirReserva();

foreach (@pedidos){
	#chomp;
	if( $_ =~ /^\s*item,mes,/ ){ # borrrar primera linea
		next;
	}
	consultar($_);
}

imprimirReserva();



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

	# AGREGAR CAMPOS: COMENTARIO Y FAMILIA/TIPO
	# print Dumper($pedidoItem);
	header($item);
	if($item ~~ @inventario){ # en inventario?
		say "Ingresando pedido: $item $mes $dia $hora $duracion";

		if($registros{$item}){ #esto se va lamar registros{item}
			my @reservasItem = @{$registros{$item}{reservas}};
			my $nReservasItem = scalar @reservasItem;
			say "| Existen $nReservasItem reservas registrdas para: $item";

			# Encapsular !!!!
			# MATRIX de reservas que tiene hasta el momento el item
			# Es mejor guardarlo en registro para no repetir
			# YA VA DECANTAR CUANDO GRABE ESTOS REGISTROS

			my %reservasMatrix = (); # {$mese}{$dia}$hora} = $duracion
			for (@reservasItem){
				my $l = $_->{duracion};
				my $h = $_->{hora};
				my $d = $_->{dia};
				my $m = $_->{mes};
				$reservasMatrix{$m}{$d}{$h} = $l;
			}



			# Buscar lugar libre en la matriz...
			if($mes ~~ %reservasMatrix){
				say "| Mes: $mes ocupado, voy a buscar en los dias:";

				if($dia ~~ %{$reservasMatrix{$mes}}){
					say "|| Dia: $dia ocupado, voy q buscar en las horas:";

					if($hora ~~ %{$reservasMatrix{$mes}{$dia}}){
						say "||| Hora: $hora ocupada, hay q buscar otra fecha disponible:";

						# LISTO hasta aca tengo QUE:
						# * Mostrar algo como el proximo dia mes hora disponible
						#   AKA Cuando vuelve el item

					}else{
						say "||| Hora: $hora libre!";


						# Antes de agregar tengo QUE:
						# * Ver si la duración no pisa otra reserva
						#   Dar opción o cortar y avisar..

						reservar($registros{$item}{reservas}, $pedidoItem);
						say "continuo."; next;
						# Despues / ademas de agregar tengo QUE:
						# * RESERVAR proximas {horas} a partir de la duracion
						# for i < $l
						# 	%reservas mes dia {i} = 0 # marcar / inhabilitar
						# }
					}

				}else{
					say "|| Dia: $dia libre!";
					reservar($registros{$item}{reservas}, $pedidoItem);
					say "continuo."; next;
					next;
				}

			}else{
				say "| Mes: $mes libre!";
				reservar($registros{$item}{reservas}, $pedidoItem);
				say "continuo."; next;
				next;
			} # Termina matrix

		}else{
			say "| No se encontraron reservas para: $item";
			$registros{$item} = {"reservas" => [$pedidoItem]}; # Revisar estructura
			say "Creo primer registro, continuo."; next;
		}

	}else{
		say "\nNo existe: $item en el inventario ###";
	}

}

sub reservar{

	# Antes de agregar tengo QUE:
	# * Ver si la duración no pisa otra fecha
	#   Dar opción o cortar y avisar ?

	my $p = $_[-1];
	push $_[0], $p;
	# mostrar esto en la matrix para ver que estebien
	print "+ Agregue la reserva: ";
	print_hash($_[0][-1]);

}




# Subs
sub imprimirReserva {

	header('Items Reservados');
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
