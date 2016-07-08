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
my $registro = $json->decode($registro_text);

my %reservas = %$registro;

imprimirReserva();

foreach (@pedidos){
	# @chomp;
	if($_ =~ /^\s*item,mes,/){ # borrrar primera linea
		next;
	}
	consultar($_);
}

imprimirReserva();


# Subs
sub consultar{
	my ($item,$mes,$dia,$hora,$duracion) =  split /\W/, $_;
	my $p = {mes=>$mes,dia=>$dia,hora=>$hora,duracion=>$duracion};

	# print Dumper($p);

	if($item ~~ @inventario){ # en inventario?
		say "\nIngresando pedido: $item $mes $dia $hora $duracion";

		if($reservas{$item}){
			my @rs = @{$reservas{$item}{reservas}};
			my $cuantas_r = scalar @rs;

			say "| Existen $cuantas_r reservas registrdas para: $item";
			my %reservasMatrix = ();# [$mese][$dia][$hora]=$duracion

			for (@rs){
				my $l = $_->{duracion};
				my $h = $_->{hora};
				my $d = $_->{dia};
				my $m = $_->{mes};
				$reservasMatrix{$m}{$d}{$h} = $l;
			}

			# la papa, ubicamos en la matriz...
			# if($mes ~~ %reservasMatrix){
			# 	say "| Mes: $mes ocupado, voy a buscar en los dias";

			# 	# if($dia ~~ %{$reservasMatrix{$mes}}){
			# 	# 	say "|| Dia: $dia ocupado, hay q buscar en las horas";
			# 	# 	# Generar contenido dummy para probar esto
			# 	# }else{
			# 	# 	say "|| Dia: $dia libre, reservo y sigo...";
			# 	# 	push @{$reservas{$item}{reservas}}, $p;
			# 	# 	say "+ Agregue la reserva: $_";
			# 	# 	next;
			# 	# }

			# }else{
			# 	say "| Mes: $mes libre, reservo y sigo...";
			# 	push @{$reservas{$item}{reservas}}, $p;
			# 	say "+ Agregue la reserva: $_";
			# 	next;
			# } # termina matrix

		}else{
			say "| No se encontraron reservas para: $item";
			$reservas{$item} = {"reservas" => [$p]}; # Revisar estructura
			say "+ Agregue una reserva para: $_";
		}

	}else{
		say "\nNo existe: $item en el inventario ###";
	}

}



# Subs
sub imprimirReserva{
# 	my @s = @_;
	foreach my $key ( keys %reservas ){
		my $cuantasReservas = scalar @{$reservas{$key}{reservas}};
		say "key: $key, - reservas: $cuantasReservas";
	}

}

