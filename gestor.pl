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
	chomp;
	if($_ =~ /^\s*item,mes,/){ # borrrar primera linea
		next;
	}
	consultar($_);
}



# Subs
sub consultar{
	my ($item,$mes,$dia,$hora,$duracion) =  split /\W/, $_;
	my $p = {mes=>$mes,dia=>$dia,hora=>$hora,duracion =>$duracion};

	# print Dumper($p);

	if($item ~~ @inventario){ # en inventario?
		 say "\nEvaluando: $item - $mes $dia $hora $duracion ###";

		if($reservas{$item}){
			my @r = @{$reservas{$item}{reservas}};
			my $cuantas_r = scalar @r;
			say "- Existen $cuantas_r reservas registrdas para: $item.";
			my $c = 0;
			foreach (@r){
				$c++;
				say "- Evaluando reserva$c q tiene mes $_->{mes}";


				if ($mes != $_->{mes}){ # comparar mes
					# push @{$reservas{$item}{reservas}}, $p; # reservo!
					say "--- Mes: $_->{mes} LIBRE";
					next;
				}else{
					say "--- Mes: $_->{mes} ocupado";
				}

			}
		}else{
			# say "- No se encontraron reservas para: $item.";
			$reservas{$item} = {"reservas" => [$mes,$dia,$hora,$duracion]};
			say "- Agregue una reserva para: $_.";
		}

	}else{
		say "\nNo existe: $item en el inventario ###";
	}
}

sub reservar{

}
# print	Dumper(%reservas);

