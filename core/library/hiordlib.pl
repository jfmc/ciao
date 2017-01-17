:- module(hiordlib, [
     map/3, map/4, map/5,
     map/6, % NOTUSED
     foldl/4,
     minimum/3,
     filter/3,
     partition/4,
     maplist/2,
     maplist/3,
     maplist/4,
     maplist/5,
     maplist/6
   ], [assertions, basicmodes, nativeprops, dcg, fsyntax, hiord, unittestdecls]).

% :- fun_eval(arith(true)).

:- doc(title, "Common higher-order predicates").

:- doc(author, "Daniel Cabeza").
:- doc(author, "Manuel Carro").
:- doc(author, "Edison Mera").
:- doc(author, "Jose F. Morales").

:- doc(module, "This library implements a few basic higher-order
   predicates for manipulating basic data structures (e.g., lists).").

:- meta_predicate map(_, pred(2), _).
:- pred map(LList, Op, RList) # "Examples of use:
@begin{verbatim}
  map([1,3,2], arg(f(a,b,c,d)), [a,c,b]) or
  map([1,3,2], nth([a,b,c,d]), [a,c,b])
  map([\"D\",\"C\"], append(\".\"), [\"D.\",\"C.\"])
@end{verbatim}
".

map([],     _) := [].
map([X|Xs], P) := [~P(X) |~map(Xs, P)].

:- load_test_module(library(lists), [nth/3, append/3]).

:- test map(A, B, C) : (A = [1, 3, 2], B = arg(f(a, b, c, d)))
	=> (C = [a, c, b]) + (not_fails, is_det).

:- test map(A, B, C) : (A = [1, 3, 2], B = nth([a, b, c, d]))
	=> (C = [a, c, b]) + (not_fails, is_det).

:- test map(A, B, C) : (A = ["D", "C"], B = append("."))
	=> (C = ["D.", "C."]) + (not_fails, is_det).

:- meta_predicate map(?, pred(3), ?, ?).
:- pred map(LList, Op, RList, Tail) # "DCG version of map.".

map([],     _) --> [].
map([X|Xs], P) --> P(X), map(Xs, P).

:- test map(A, B, C, D) :
	(
	    A = [1, 3, 2],
	    B = (''(L, [E|T], T) :- arg(L, f(a, b, c, d), E)),
	    D = [x, y])
	=> (C = [a, c, b, x, y]) + (not_fails, is_det).

:- meta_predicate map(?, ?, pred(4), ?, ?).

map([],     [], _) --> [].
map([X|Xs], [Y|Ys], P) --> P(X, Y), map(Xs, Ys, P).

:- meta_predicate map(?, ?, ?, pred(5), ?, ?).

map([],     [],     [],     _) --> [].
map([X|Xs], [Y|Ys], [Z|Zs], P) --> P(X, Y, Z), map(Xs, Ys, Zs, P).

:- meta_predicate foldl(_, _, pred(3), _).
:- pred foldl(List, Seed, Op, Result) # "Example of use:
@begin{verbatim}
?- foldl([\"daniel\",\"cabeza\",\"gras\"], \"\", 
         (''(X,Y,Z) :- append(X, \" \"||Y, Z)), R).

R = \"daniel cabeza gras \" ? 
@end{verbatim}
".

foldl([],     Seed, _Op) := Seed.
foldl([X|Xs], Seed, Op) := ~Op(X, ~foldl(Xs, Seed, Op)).

:- meta_predicate minimum(_, pred(2), _).
:- pred minimum(?List, +SmallerThan, ?Minimum) : list * callable *
	term # "@var{Minimum} is the smaller in the nonempty list
	@var{List} according to the relation @var{SmallerThan}:
	@pred{SmallerThan(X, Y)} succeeds iff X is smaller than Y.".

minimum([X|Xs], Pred, Min) :- minimum_carry(Xs, Pred, X, Min).
minimum_carry([],     _Pred, M,        M).
minimum_carry([X|Xs], Pred,  MinSoFar, Min) :-
	(
	    Pred(MinSoFar, X) ->
	    minimum_carry(Xs, Pred, MinSoFar, Min)
	;
	    minimum_carry(Xs, Pred, X, Min)
	).

:- meta_predicate filter(pred(1), +, ?).
:- pred filter(+P, +Xs, ?Ys)
	:: (callable(P), list(Xs), list(Ys)) + is_det
   # "@var{Ys} contains all elements @var{X} of @var{Xs} such that
     @tt{P(X)} holds (preserving the order)".

filter(Goal, List, Included) :-
	filter_(List, Goal, Included).

filter_([], _, []).
filter_([X|Xs], P, Ys) :-
	( call(P, X) ->
	    Ys = [X|Ys0]
	; Ys = Ys0
	),
	filter_(Xs, P, Ys0).

:- meta_predicate partition(pred(1), ?, ?, ?).
:- pred partition(+P, +Xs, ?Ys, ?Zs) ::
   callable * list * list * list
   # "@var{Ys} contains all elements @var{X} of @var{Xs} such that
      @tt{P(X)} holds, and @var{Zs} all that does not (preserving the
      order)".

partition(P, Xs, Ys, Zs) :-
	partition_(Xs, P, Ys, Zs).

partition_([], _, [], []).
partition_([X|Xs], P, Ys, Zs) :-
	( P(X) ->
	    Ys = [X|Ys0],
	    Zs = Zs0
	; Ys = Ys0,
	  Zs = [X|Zs0]
	),
	partition_(Xs, P, Ys0, Zs0).

:- test partition(P, Xs, Ys, Zs)
	: (P='>'(4), Xs=[1, 2, 3, 4, 5, 6])
	=> (Ys=[5, 6], Zs=[1, 2, 3, 4])
	+ not_fails.

% ---------------------------------------------------------------------------
% maplist/N

:- meta_predicate maplist(pred(1), ?).
:- pred maplist(+P, +Xs) ::
	(callable(P), list(Xs))
   # "@tt{P(X)} succeeds for each element @var{X} of @var{Xs}".
%
:- meta_predicate maplist(pred(2), ?, ?).
:- pred maplist(+P, +Xs, ?Ys) ::
	(callable(P), list(Xs), list(Ys))
   # "@tt{P(X,Y)} succeeds for each successive pair
      (@var{X},@var{Y}) from
       @var{Xs}, @var{Ys}.".
%
:- meta_predicate maplist(pred(3), ?, ?, ?).
:- pred maplist(+P, +Xs, ?Ys, ?Zs) ::
	(callable(P), list(Xs), list(Ys), list(Zs))
   # "@tt{P(X,Y,Z)} succeeds for each successive pair
      (@var{X},@var{Y},@var{Z}) from
       @var{Xs}, @var{Ys}, @var{Zs}.".
%
:- meta_predicate maplist(pred(4), ?, ?, ?, ?).
:- pred maplist(+P, +Xs, ?Ys, ?Zs, ?Vs) ::
	(callable(P), list(Xs), list(Ys), list(Zs), list(Vs))
   # "@tt{P(X,Y,Z,V)} succeeds for each successive pair
      (@var{X},@var{Y},@var{Z},@var{V}) from
       @var{Xs}, @var{Ys}, @var{Zs}, @var{Vs}.".
%
:- meta_predicate maplist(pred(5), ?, ?, ?, ?, ?).
:- pred maplist(+P, +Xs, ?Ys, ?Zs, ?Vs, ?Ws) ::
	(callable(P), list(Xs), list(Ys), list(Zs), list(Vs), list(Ws))
   # "@tt{P(X,Y,Z,V,W)} succeeds for each successive pair
      (@var{X},@var{Y},@var{Z},@var{V},@var{W}) from
       @var{Xs}, @var{Ys}, @var{Zs}, @var{Vs}, @var{Ws}.".

maplist(P, Xs) :-
	maplist1(Xs, P).
maplist(P, Xs, Ys) :-
	maplist2(Xs, P, Ys).
maplist(P, Xs, Ys, Zs) :-
	maplist3(Xs, P, Ys, Zs).
maplist(P, Xs, Ys, Zs, Vs) :-
	maplist4(Xs, P, Ys, Zs, Vs).
maplist(P, Xs, Ys, Zs, Vs, Ws) :-
	maplist5(Xs, P, Ys, Zs, Vs, Ws).

:- meta_predicate maplist1(?, pred(1)).
:- meta_predicate maplist2(?, pred(1), ?).
:- meta_predicate maplist3(?, pred(1), ?, ?).
:- meta_predicate maplist4(?, pred(1), ?, ?, ?).
:- meta_predicate maplist5(?, pred(1), ?, ?, ?, ?).

maplist1([], _).
maplist1([X|Xs], P) :-
	call(P, X),
	maplist1(Xs, P).

maplist2([], _, []).
maplist2([X|Xs], P, [Y|Ys]) :-
	call(P, X, Y),
	maplist2(Xs, P, Ys).

maplist3([], _, [], []).
maplist3([X|Xs], P, [Y|Ys], [Z|Zs]) :-
	call(P, X, Y, Z),
	maplist3(Xs, P, Ys, Zs).

maplist4([], _, [], [], []).
maplist4([X|Xs], P, [Y|Ys], [Z|Zs], [V|Vs]) :-
	call(P, X, Y, Z, V),
	maplist4(Xs, P, Ys, Zs, Vs).

maplist5([], _, [], [], [], []).
maplist5([X|Xs], P, [Y|Ys], [Z|Zs], [V|Vs], [W|Ws]) :-
	call(P, X, Y, Z, V, W),
	maplist5(Xs, P, Ys, Zs, Vs, Ws).


