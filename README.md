[![Actions Status](https://github.com/skaji/Mojo-Promise-Limitter/workflows/linux/badge.svg)](https://github.com/skaji/Mojo-Promise-Limitter/actions)

# NAME

Mojo::Promise::Limitter - limit outstanding calls to Mojo::Promise

# SYNOPSIS

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

# DESCRIPTION

Mojo::Promise::Limitter allows you to limit outstanding calls to `Mojo::Promise`s.
This is a Perl port of [https://github.com/featurist/promise-limit](https://github.com/featurist/promise-limit).

# MOTIVATION

I sometimes want to limit outstanding calls to reduce load on external services,
or to reduce some resource (cpu, memory, etc) usage.
For example, without some mechanism to limit outstanding calls,
the following code open 5 connections to metacpan.

    my $http = Mojo::UserAgent->new;
    Mojo::Promise->all_settled(
      $http->get_p("https://metacpan.org/release/App-cpm"),
      $http->get_p("https://metacpan.org/release/Minilla"),
      $http->get_p("https://metacpan.org/release/Mouse"),
      $http->get_p("https://metacpan.org/release/Perl6-Build"),
      $http->get_p("https://metacpan.org/release/Test-CI"),
    )->wait;

With Mojo::Promise::Limitter, you can easily limit concurrent connections.
See [eg/http.pl](https://github.com/skaji/Mojo-Promise-Limitter/tree/master/eg/http.pl)
for real world example.

# EVENTS

Mojo::Promise::Limitter inherits all events from [Mojo::EventEmitter](https://metacpan.org/pod/Mojo%3A%3AEventEmitter) and can emit the
following new ones.

## run

    $limitter->on(run => sub {
      my ($limitter, $name) = @_;
      ...;
    });

## remove

    $limitter->on(remove => sub {
      my ($limitter, $name) = @_;
      ...;
    });

## queue

    $limitter->on(queue => sub {
      my ($limitter, $name) = @_;
      ...;
    });

## dequeue

    $limitter->on(dequeue => sub {
      my ($limitter, $name) = @_;
      ...;
    });

# METHODS

Mojo::Promise::Limitter inherits all methods from [Mojo::EventEmitter](https://metacpan.org/pod/Mojo%3A%3AEventEmitter) and implements
the following new ones.

## new

    my $limitter = Mojo::Promise::Limitter->new($concurrency);

Constructs Mojo::Promise::Limitter object.

## limit

    my $promise = $limitter->limit($sub);
    my $promise = $limitter->limit($sub, $name);

Limits calls to `$sub` based on `concurrency`,
where `$sub` is a subroutine reference that must return a promise, and
`$name` is an optional argument which will be used in events.
`$limitter->limit($sub)` returns a promise that resolves or rejects
the same value or error as `$sub`.
All subroutine references are executed in the same order in which
they were passed to `$limitter->limit` method.

# SEE ALSO

[https://github.com/featurist/promise-limit](https://github.com/featurist/promise-limit)

# AUTHOR

Shoichi Kaji <skaji@cpan.org>

# COPYRIGHT AND LICENSE

Copyright 2020 Shoichi Kaji <skaji@cpan.org>

The ISC License
