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

	if($item ~~ @inventario){ # en inventario?
		# say "-- $item $mes $dia $hora $duracion";

		if($reservas{$item}){
			my @r = @{$reservas{$item}{reservas}};
			say "- Existen reservas registrdas para: $item.";
			# my @meses =$reservas{$item}{}
			foreach (@r){

				for my $key ( keys %$_ ) {
					say "$key : $_->{$key}";
				}
				# comparar mes con el mes de cada $reservas{$item}

			}
		}else{
			#say "- No se encontraron reservas para: $item.";
			$reservas{$item} = {"reservas" => [$mes,$dia,$hora,$duracion]};
			say "- Agregué una reserva para: $_.";
		}

	}else{
		say "No existe: $item en el inventario.";
	}
}

# print	Dumper(%reservas);

