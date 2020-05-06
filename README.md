[![Actions Status](https://github.com/skaji/Mojo-Promise-Limiter/workflows/linux/badge.svg)](https://github.com/skaji/Mojo-Promise-Limiter/actions)

# NAME

Mojo::Promise::Limiter - limit outstanding calls to Mojo::Promise

# SYNOPSIS

    use Mojo::Promise::Limiter;
    use Mojo::Promise;
    use Mojo::IOLoop;

    my $limiter = Mojo::Promise::Limiter->new(2);

    my @job = 'a' .. 'e';

    Mojo::Promise->all(
      map { my $name = $_; $limiter->limit(sub { job($name) }) } @job,
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

Mojo::Promise::Limiter allows you to limit outstanding calls to `Mojo::Promise`s.
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

With Mojo::Promise::Limiter, you can easily limit concurrent connections.
See [eg/http.pl](https://github.com/skaji/Mojo-Promise-Limiter/tree/master/eg/http.pl)
for real world example.

# EVENTS

Mojo::Promise::Limiter inherits all events from [Mojo::EventEmitter](https://metacpan.org/pod/Mojo%3A%3AEventEmitter) and can emit the
following new ones.

## run

    $limiter->on(run => sub {
      my ($limiter, $name) = @_;
      ...;
    });

## remove

    $limiter->on(remove => sub {
      my ($limiter, $name) = @_;
      ...;
    });

## queue

    $limiter->on(queue => sub {
      my ($limiter, $name) = @_;
      ...;
    });

## dequeue

    $limiter->on(dequeue => sub {
      my ($limiter, $name) = @_;
      ...;
    });

# METHODS

Mojo::Promise::Limiter inherits all methods from [Mojo::EventEmitter](https://metacpan.org/pod/Mojo%3A%3AEventEmitter) and implements
the following new ones.

## new

    my $limiter = Mojo::Promise::Limiter->new($concurrency);

Constructs Mojo::Promise::Limiter object.

## limit

    my $promise = $limiter->limit($sub);
    my $promise = $limiter->limit($sub, $name);

Limits calls to `$sub` based on `concurrency`,
where `$sub` is a subroutine reference that must return a promise, and
`$name` is an optional argument which will be used in events.
`$limiter->limit($sub)` returns a promise that resolves or rejects
the same value or error as `$sub`.
All subroutine references are executed in the same order in which
they were passed to `$limiter->limit` method.

# SEE ALSO

[https://github.com/featurist/promise-limit](https://github.com/featurist/promise-limit)

# AUTHOR

Shoichi Kaji <skaji@cpan.org>

# COPYRIGHT AND LICENSE

Copyright 2020 Shoichi Kaji <skaji@cpan.org>

The ISC License
