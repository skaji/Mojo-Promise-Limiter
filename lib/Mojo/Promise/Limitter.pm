package Mojo::Promise::Limitter;
use Mojo::Base -base;
use Mojo::Promise;

our $VERSION = '0.001';

has outstanding => 0;
has concurrency => 0;
has jobs => sub { [] };

sub new {
    my ($class, $concurrency) = @_;
    $class->SUPER::new(concurrency => $concurrency);
}

sub remove {
    my $self = shift;
    $self->{outstanding}--;
    if ($self->outstanding < $self->concurrency) {
        $self->dequeue;
    }
}

sub dequeue {
    my $self = shift;
    my $job = shift @{$self->jobs};
    if ($job) {
        $self->run($job->{sub})->then($job->{resolve}, $job->{reject});
    }
}

sub queue {
    my ($self, $sub) = @_;
    Mojo::Promise->new(sub {
        my ($resolve, $reject) = @_;
        push @{$self->jobs}, { sub => $sub, resolve => $resolve, reject => $reject };
    });
}

sub run {
    my ($self, $sub) = @_;
    $self->{outstanding}++;

    $sub->()->then(
        sub {
            my @result = @_;
            $self->remove;
            return @result;
        },
        sub {
            my @error = @_;
            $self->remove;
            Mojo::Promise->reject(@error);
        },
    );

}

sub limit {
    my ($self, $sub) = @_;
    if ($self->outstanding >= $self->concurrency) {
        return $self->queue($sub);
    } else {
        return $self->run($sub);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::Promise::Limitter - limit outstanding calls to Mojo::Promise

=head1 SYNOPSIS

  use Mojo::Promise::Limitter;
  use Mojo::Promise;
  use Mojo::IOLoop;

  my $limitter = Mojo::Promise::Limitter->new(2);

  my @job = 'a' .. 'e';

  Mojo::Promise->all(
    map { my $name = $_; $limitter->limit(sub { job($name) }) } @job,
  )->then(sub {
    my @result = @_;
    warn "\n";
    warn "results: ", (join ", ", map { $_->[0] } @result), "\n";
  })->wait;

  sub job {
    my $name = shift;
    my $text = "job $name";
    warn "started $text\n";
    return Mojo::Promise->new(sub {
      my $resolve = shift;
      Mojo::IOLoop->timer(0.1 => sub {
        warn "        $text finished\n";
        $resolve->($text);
      });
    });
  }

will outputs:

  started job a
  started job b
          job a finished
          job b finished
  started job c
  started job d
          job c finished
          job d finished
  started job e
          job e finished

  results: job a, job b, job c, job d, job e

=head1 DESCRIPTION

Mojo::Promise::Limitter allows you to limit outstanding calls to C<Mojo::Promise>s.
This is a Perl port of L<https://github.com/featurist/promise-limit>.

=head1 METHODS

L<Mojo::Promise::Limitter> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head2 new

  my $limitter = Mojo::Promise::Limitter->new($concurrency);

Constructs C<Mojo::Promise::Limitter> object.

=head2 limit

  my $promise = $limitter->limit($sub);

Limits calls to C<$sub> based on C<concurrency>,
where C<$sub> is a subroutine reference that must return a promise.
C<< $limitter->limit($sub) >> returns a promise that resolves or rejects
the same value or error as C<$sub>.
All subroutine references are executed in the same order in which
they were passed to C<< $limitter->limit >> method.

=head1 SEE ALSO

L<https://github.com/featurist/promise-limit>

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Shoichi Kaji <skaji@cpan.org>

The ISC License

=cut
