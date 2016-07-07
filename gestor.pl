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



foreach (@pedidos){
	#@chomp;
	if($_ =~ /^\s*item,mes,/){ # borrrar primera linea
		next;
	}
	consultar($_);
}



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

			say "- Existen $cuantas_r reservas registrdas para: $item.";
			my @reservas_matrix = ();# [$mese][$dia][$hora]=$duracion


			my $c = 1;
			for (@rs){
				my $l = $_->{duracion};
				my $h = $_->{hora};
				my $d = $_->{dia};
				my $m = $_->{mes};

				$reservas_matrix[$m][$d][$h] = $l;
				# push @{ $h[$_->{hora}] }, $l;
				say "+ Matrixeando reserva $c ";
				say "duracion en la matrix: $reservas_matrix[$m][$d][$h]";


				# push @{ $reservas_matrix[$m] }, $l;

				# $reservas_matrix[$m][$d][$h] = $l;


			# 	# if ($mes != $_->{mes}){ # comparar mes
			# 	# 	# push @{$reservas{$item}{reservas}}, $p; # reservo!
			# 	# 	say "--- hay lugar en mes: $_->{mes} LIBRE";
			# 	# 	next;
			# 	# }else{
			# 	# 	say "--- Mes: $_->{mes} ocupado";
			# 	# }

				$c++;
			}




		}else{
			# say "- No se encontraron reservas para: $item.";
			$reservas{$item} = {"reservas" => [$mes,$dia,$hora,$duracion]};
			say "+ Agregue una reserva para: $_";
		}

	}else{
		say "\nNo existe: $item en el inventario ###";
	}
}

sub reservar{

}
# print	Dumper(%reservas);




