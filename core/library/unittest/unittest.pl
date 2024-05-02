:- module(unittest, [], [assertions, regtypes, isomodes, nativeprops, dcg, fsyntax, hiord, datafacts, define_flag]).

:- doc(title, "Unit testing").

:- doc(author, "Edison Mera").
:- doc(author, "Pedro L@'{o}pez").
:- doc(author, "Manuel Hermenegildo").
:- doc(author, "Jose F. Morales").
:- doc(author, "Alvaro Sevilla San Mateo").
:- doc(author, "Nataliia Stulova").
:- doc(author, "Ignacio Casso").
:- doc(author, "Jose Luis Bueno").

:- doc(module, "
   The Ciao assertion language (see @ref{The Ciao
   assertion language}) allows writing @index{tests} (including
   @index{unit tests}) by means of @index{test assertions}. These
   assertions make it possible to write specific test cases at the
   predicate level. This library contains predicates that can be used
   to run tests in modules and gather or pretty-print the results. It
   also provides some special properties that are convenient when
   writing tests and the corresponding run-time support.

@subsection{Writing test assertions}
@cindex{writing unit tests}

   As described in @ref{The Ciao assertion language} a @index{test
   assertion} is written as follows:

@begin{verbatim}
:- test predicate(A1, A2, ..., An) 
   :  <Precondition>
   => <Postcondition>
   +  <Global properties>
   #  <Comment>.
@end{verbatim}

   Where the fields of the test assertion have the usual meaning in
   Ciao assertions, i.e., they contain conjunctions of properties
   which must hold at certain points in the execution. Here we give a
   somewhat more operational (``test oriented'') reading to these
   fields: 

   @begin{itemize}
   @item @pred{predicate/n} is the predicate to be tested.

   @item @var{Precondition} is a goal (a literal or a conjuntion of
   literals) that is called before the predicate being tested, and can
   be used to generate values of the input parameters. While in some
   other types of assertions these preconditions contain properties to
   be checked, the typical role of the preconditions here is to
   provide concrete input values for which the predicate can be
   actually executed.

   @item @var{Postcondition} is a goal that should succeed after
   @pred{predicate/n} has been called. This is used to test that the
   output of the predicate is the correct one for the input
   provided.

   @item @var{Global properties} specifies some global properties that
   the predicate should meet, in the same way as other assertions. For
   example, @code{not_fails} means that the predicate does not fail,
   @code{exception(error(a,b))} means that the predicate should throw
   the exception @code{error(a,b)}, and so on.

   @item @var{Comment} is a string that documents the test.
   @end{itemize}

   The following are some example tests for a complex number evaluator
   (see @ref{Examples (unittest)} for the full code):

@begin{verbatim}
:- module(ceval2, [ceval/2], [assertions, regtypes, nativeprops]).

:- test ceval(A, B) : (A = c(3, 4) + c(1, 2) - c(2, 3))
    => (B = c(2, 3)) + (not_fails, is_det).

:- test ceval(A, B) : (A = c(3, 4) * c(1, 2) / c(1, 2))
    => (B = c(3.0, 4.0)) + (not_fails, is_det).

ceval(A,   A) :- complex(A), !.
ceval(A+B, C) :- ceval(A, CA), ceval(B, CB), add(CA, CB, C).
ceval(A-B, C) :- ceval(A, CA), ceval(B, CB), sub(CA, CB, C).
ceval(A*B, C) :- ceval(A, CA), ceval(B, CB), mul(CA, CB, C).
ceval(A/B, C) :- ceval(A, CA), ceval(B, CB), div(CA, CB, C).

...

:- regtype complex/1.
:- export(complex/1).

complex(c(A, B)) :-
    num(A),
    num(B).
@end{verbatim}

   Test assertions can be combined with other assertions: 

@begin{verbatim}
:- test ceval(A, B) : (A = c(3, 4) + c(1, 2) - c(2, 3))
    => (B = c(2, 3)) + (not_fails, is_det).
:- test ceval(A, B) : (A = c(3, 4) * c(1, 2) / c(1, 2))
    => (B = c(3.0, 4.0)) + (not_fails, is_det).
:- check pred ceval/2 : gnd * term => gnd * complex.
@end{verbatim}

   Test assertions can also take the standard assertion status
   prefixes. In particular, a status of @tt{false} can be used to
   state that a test fails. This can be useful to flag bugs as known.

@begin{verbatim}
:- false test ceval(A, B) : (A = c(3, 4) + c(1, 2) - c(2, 3))
    => (B = c(2, 3)) + (not_fails, is_det).
@end{verbatim}

   Tests with a @tt{false} (or @tt{true}) prefix are not run. 

   There are some specific properties that only apply to testing which
   are provided in module @lib{unittest_props.pl} (see @ref{Special
   properties for testing}). For example, the limit to the number of
   solutions to be generated for the tested predicate can be set with
   the property @code{try_sols(N)}, a timeout to a test can be set
   with the property @code{timeout(N)}, etc.

@subsection{Unit tests as examples}

   The special property @tt{example} can be used to mark the unit test
   as an example, so that it is documented as such in manuals. The
   default behavior in @apl{lpdoc} is to not include the unit tests in
   manuals unless they are marked this way. For example, the following
   test would be included in the manual as an example:

@begin{verbatim}
:- test ceval(A, B) : (A = c(3, 4) + c(1, 2) - c(2, 3))
    => (B = c(2, 3)) + (not_fails, is_det, example).
@end{verbatim}

@subsection{Running unit tests}

There are several ways to run the unit tests @cindex{running unit tests}:

@begin{itemize}
@item Select @bf{CiaoDbg} menu within the development environment, e.g., 
  select the @tt{Run tests in current module}.
@item Run all tests in a given bundle @cindex{bundle} by running the
  following command at the top level of the source tree or a bundle:
@begin{verbatim}
ciao test
@end{verbatim}
@item Run from the top level, loading this module (@lib{unittest.pl})
  and calling the appropiate predicates (e.g., @pred{run_tests/3})
  (see the module @ref{Usage and interface} section below). This can
  also be done from a program, provided it imports this module.
@end{itemize}

@subsection{Combination with run-time tests}

   These tests can be combined with the run-time checking of other
   assertions present in the involved modules. This can be done by
   including the @lib{rtchecks} package in the desired modules.  Any
   @tt{check} assertions present in the code will then be checked
   dynamically during the execution of the tests and can detect
   additional errors.

@subsection{Integration tests}

   If you need to write tests for predicates that are spread over
   several modules, but work together, it may be useful to create a
   separate module, and reexport the predicates required to build the
   tests. This allows performing @em{integration testing}, using the
   syntax and functionality of the test assertions.  

").

:- use_module(engine(stream_basic)).
:- use_module(library(streams), [nl/0, nl/1]).
:- use_module(engine(messages_basic), [message/2, messages/1]).
:- use_module(library(sort), [sort/2]).
:- use_module(library(aggregates), [findall/3]).
:- use_module(library(system), [file_exists/1]).
:- use_module(library(lists), [member/2, last/2]).
:- use_module(library(hiordlib), [maplist/2, maplist/3]).
:- use_module(library(pathnames), [pathname/1]).

:- use_module(library(source_tree), [
    current_file_find/3,
    remove_dir/1
]).

:- use_module(library(unittest/unittest_db)).
:- use_module(library(unittest/unittest_regression), [
    save_output/1,
    brief_compare/2,
    compare/1,
    test_description/6 % move somewhere else
]).

:- doc(bug, "Currently @bf{only the tests defined for exported
   predicates} are executed.  This is a limitation of the current
   implementation that will be corrected in the future.").

% ---------------------------------------------------------------------------

:- use_module(engine(runtime_control), [current_prolog_flag/2]).

define_flag(unittest_default_timeout, integer, 600000). % TODO: move somewhere else?

% ----------------------------------------------------------------------
%! # Run unittests

:- reexport(library(unittest/unittest_runner_common), [test_option/1]).

% TODO: missing support for redirecting stdin(_)?

:- export(test_action/1).
:- doc(test_action/1, "A global option that specifies a testing
   routine. The current set of actions is:
   @begin{itemize}
   @item @tt{check} : run tests and temporarily save
     results in the auto-rewritable @tt{module.testout} file;
   @item @tt{show_results} : print the test results;
   @item @tt{status(S)} : unify S with the overall test status;
   @item @tt{summaries(S)} : unify S with the test summaries;
   @item @tt{stats(S)} : unify S with the statistical summary;
   @item @tt{save} : save test results file in @tt{module.testout-saved} file;
   @item @tt{briefcompare} : check whether current and saved test
     output files differ;
   @item @tt{briefcompare(S)} : like @tt{briefcompare}, unfiy S with status;
   @item @tt{compare} : see the differences in the current and saved
     test output files in the diff format;
   @end{itemize}").

:- regtype test_action(Action) # "@var{Action} is a testing action".

test_action := check | show_results.
test_action := status(_) | summaries(_) | stats(_).
test_action := save | briefcompare | briefcompare(_) | compare.

% ---------------------------------------------------------------------------
%! ## Custom run_tests/3 calls
% (see run_test/3)

:- export(run_tests_in_module/1).
:- pred run_tests_in_module(Alias) : sourcename(Alias)
# "Executes all the tests for @var{Alias} and show the results
   (without further options). Defined as follows:
   @includedef{run_tests_in_module/1}".

run_tests_in_module(Alias) :-
    run_tests(Alias, [], [check, show_results]).

:- export(run_tests_in_module/2).
:- pred run_tests_in_module(Alias, Opts)
   : (sourcename(Alias), list(test_option,Opts))
# "Executes all the tests for @var{Alias} and show the
   results. Defined as follows: @includedef{run_tests_in_module/2}".

run_tests_in_module(Alias, Opts) :-
    run_tests(Alias, Opts, [check, show_results]).

:- export(run_tests_in_module_check_exp_assrts/1).
:- pred run_tests_in_module_check_exp_assrts(Alias) : sourcename(Alias)
# "Executes all the tests for @var{Alias} and show the results, with
   the @tt{rtc_entry} option. Defined as follows:
   @includedef{run_tests_in_module_check_exp_assrts/1}".

run_tests_in_module_check_exp_assrts(Alias) :-
    run_tests(Alias, [rtc_entry], [check, show_results]).

:- export(run_tests_in_module/3).
:- pred run_tests_in_module(Alias, Opts, TestSummaries)
   : (sourcename(Alias), list(test_option,Opts))
   => list(TestSummaries)
# "Executes all the tests for @var{Alias}. Unify @var{TestSummaries}
   with the test results. Defined as follows:
   @includedef{run_tests_in_module/3}".

run_tests_in_module(Alias, Opts, TestSummaries) :-
    run_tests(Alias, Opts, [check, summaries(TestSummaries)]).

:- export(run_tests_in_dir_rec/3).
:- pred run_tests_in_dir_rec(BaseDir, Opts, S) : pathname * list(test_option) * var
# "Executes all the tests in the modules of the given directory and
   its subdirectories (see @tt{dic_rec} test option). Unify @var{S}
   with 1 if all test passed or 0 otherwise. Defined as follows:
   @includedef{run_tests_in_dir_rec/3}".

run_tests_in_dir_rec(BaseDir, Opts, S) :-
    run_tests(BaseDir, [dir_rec|Opts], [check, show_results, status(S)]).

:- export(show_test_output/2).
:- pred show_test_output(Alias, Format) : (sourcename(Alias), atm(Format))
# "Show the test results for @var{Alias}, where @var{Format}
   specifies: @tt{output} for test full trace, @tt{stats} for a
   statistical summary only, @tt{full} for both.".

show_test_output(Alias, Format) :-
    ( Format = output -> Opts = [nostats]
    ; Format = stats -> Opts = [onlystats]
    ; Format = full -> Opts = []
    ),
    run_tests(Alias, Opts, [show_results]).

% ---------------------------------------------------------------------------
%! ## Main run_tests

:- export(run_tests/3).
:- pred run_tests(Target, Opts, Actions)
   : (sourcename(Target), list(test_option,Opts), list(test_action, Actions))
# "Perform the test action @var{Actions} on the test target
  @var{Target} with options @var{Opts}.".

run_tests(Target, Opts0, Actions) :-
    get_filters(Opts0, Filter, Opts),
    check_opts(Opts),
    check_actions(Actions),
    ( member(saved_vers, Opts) -> SelVers = saved
    ; SelVers = new
    ),
    decide_modules_to_test(Target, Opts, Modules),
    %
    run_tests_all_mods(Modules, Filter, Opts, Actions, SelVers),
    %
    ( requires_summary(Actions, Opts) ->
        do_summary(Modules, Filter, Actions, SelVers)
    ; true
    ),
    % (actions for regression tests)
    regr_action(Modules, Actions),
    % (free memory)
    cleanup_modules_under_test,
    cleanup_test_db,
    cleanup_test_results.

run_tests_all_mods([], _, _, _, _).
run_tests_all_mods([Module|Modules], Filter, Opts, Actions, SelVers) :-
    run_tests_one_mod(Module, Filter, Opts, Actions, SelVers),
    run_tests_all_mods(Modules, Filter, Opts, Actions, SelVers).

run_tests_one_mod(Module, Filter, Opts, Actions, SelVers) :-
    ( member(check, Actions) -> DoCheck = yes ; DoCheck = no ),
    ( \+ get_opt(onlystats, Opts), member(show_results, Actions) ->
        ShowRes = yes
    ; ShowRes = no
    ),
    % Load code or test db (as required)
    ( DoCheck = yes ->
        load_tests(Module) % (fails if the module had errors)
    ; ShowRes = yes ->
        check_restore_test_input(Module, SelVers)
    ; fail % nothing to do
    ),
    !,
    % run the tests and show results
    begin_messages,
    ( DoCheck = yes ->
        ( Filter = [] -> SaveRes = yes
        ; % TODO: show warning only if ShowRes=no?
          SaveRes = no,
          message(warning, ['running tests with filters will not save results'])
        ),
        check_tests_one_mod(Module, Filter, Opts, SaveRes, ShowRes)
    ; ShowRes = yes ->
        load_results(Module, SelVers),
        show_results_one_mod(Module, Filter, Opts)
    ; throw(bug) % (this should not happen)
    ),
    end_messages,
    % Cleanup code if needed (no longer needed)
    ( DoCheck = yes -> cleanup_code_and_related_assertions ; true ).
run_tests_one_mod(_Module, _Filter, _Opts, _Actions, _SelVers).

% Show the results (directly from test_output_db/2)
show_results_one_mod(Module, Filter, Opts) :-
    ( % (failure-driven loop)
      get_test_in(Module, Filter, TestId, TestIn),
      test_output_db(TestId, TRes),
        show_test_res(TestIn, TRes, Opts),
        fail
    ; true
    ).

% Check run_tests options
check_opts([]).
check_opts([Opt|Opts]) :-
    ( var(Opt) -> throw(error(uninstantiated_option, run_test/3))
    ; test_option(Opt) -> true
    ; throw(error(unknown_option(Opt), run_tests/3))
    ),
    check_opts(Opts).

% options with some default values
get_opt(stdout(X), Opts) :- member(stdout(X0), Opts), !, X = X0.
get_opt(stdout(X), _Opts) :- !, X = dump.
get_opt(stderr(X), Opts) :- member(stderr(X0), Opts), !, X = X0.
get_opt(stderr(X), _Opts) :- !, X = dump.
get_opt(Opt, Opts) :- member(Opt, Opts).

% Get filters from option list
get_filters([], [], []).
get_filters([filter(Filter)|Opts0], [Filter|Filters], Opts) :- !,
    get_filters(Opts0, Filters, Opts).
get_filters([Opt|Opts0], Filters, [Opt|Opts]) :-
    get_filters(Opts0, Filters, Opts).

% Check run_tests actions
check_actions([]).
check_actions([Action|Actions]) :-
    ( var(Action) -> throw(error(uninstantiated_action, run_test/3))
    ; test_action(Action) -> true
    ; throw(error(unknown_action(Action), run_tests/3))
    ),
    check_actions(Actions).

% ---------------------------------------------------------------------------
%! # Decide modules to test (frontend)

:- use_module(engine(internals), [opt_suff/1]).
:- use_module(library(compiler/c_itf), [module_from_base/2]).

% TODO: keep it simple, use ciaopp for advanced stuff?

decide_modules_to_test(Target, Opts, Modules) :-
    assert_modules_to_test(Target, Opts),
    findall(Path-Module,
            (module_base_path_db(Module,_,Path)),
            PathsModules0),
    sort(PathsModules0, PathsModules), % because order is not stable across different intallations (e.g., mine (IC) and Gitlab's)
    unzip(PathsModules,_,Modules).

unzip([],[],[]).
unzip([A-B|L],[A|As], [B|Bs]) :- unzip(L,As,Bs).

% asserts in module_base_path/3 facts the modules that are required
% to be tested
assert_modules_to_test(Target, Opts) :-
    cleanup_modules_under_test,
    ( get_opt(dir_rec, Opts) ->
        (  % (failure-driven loop)
          current_file_find(testable_module, Target, Path),
            assert_module_under_test(Path),
            fail
        ; true
        )
    ; assert_module_under_test(Target)
    ).

assert_module_under_test(Alias) :- % arg is a module
    ( % arg is an alias path
      current_fact(opt_suff(Suff)),
      absolute_file_name(Alias, Suff, '.pl', '.', AbsFileName, Base, _AbsDir) ->
        module_from_base(Base, Module)
    ; fail
    ),
    assertz_fact(module_base_path_db(Module, Base, AbsFileName)).
% TODO: check FileName exists, just in case?

% ---------------------------------------------------------------------------
%! # Read test assertions from modules (frontend)

% TODO: use p_unit (it may be faster, specially for loading many modules)

:- use_module(library(assertions/assrt_lib), [
    cleanup_code_and_related_assertions/0,
    assertion_read/9,
    clause_read/7,
    get_code_and_related_assertions/5,
    assertion_body/7
]).
:- use_module(library(terms), [atom_concat/2]).
:- use_module(library(bundle/bundle_paths), [bundle_shorten_path/2]).

:- data compilation_error/0.

% Load the module and fill test_db/8 with tests assertions.
% Keep the program loaded in memory (it will be required for checking assertions later).
% Save test_db/8 in .testin file (required to show the test results).
load_tests(Module) :-
    cleanup_test_db,
    module_base_path_db(Module,Base,Path),
    cleanup_code_and_related_assertions, % TODO: check if last get_code_and_related_assertion read this module
    retractall_fact(compilation_error),
    intercept(
        get_code_and_related_assertions(Path, Module, Base, '.pl', _AbsDir),
        compilation_error,
        assertz_fact(compilation_error) % just "fail" or "!, fail" does not work. Why? Spurious choicepoints in get_code_and_related_assertions/5?
    ),
    ( retract_fact(compilation_error) -> !, % TODO: cut should not be needed here
        % compilation failed, make sure there is no testin file and fail
        remove_test_input(Module,new),
        fail
    ; true
    ),
    %
    file_test_input(Module,new,TestInFile),
    open(TestInFile, write, SI),
    ( % (failure-driven loop)
      get_test(Module, TestId, Type, Pred, Body0, Dict, Src0, LB, LE),
        bundle_shorten_path(Src0,Src),
        assertion_body(Pred,Compat,Calls,Succ,Comp0,Comment,Body0),
        split_comp_props(Comp0, TestOptions0, Comp),
        texec_warning(Type, Comp, Pred, asrloc(loc(Src,LB,LE))),
        check_noexvar_succ(Pred, Succ, asrloc(loc(Src,LB,LE))),
        assertion_body(Pred,Compat,Calls,Succ,Comp,Comment,Body),
        functor(Pred, F, A),
        get_test_options(TestOptions0,Base,TestOptions),
        % message(error0, ['log: ', $(t(TestId, Module, F, A, loc(Src, LB, LE)))]),
        assertz_fact(test_db(TestId, Module, F, A, Dict, TestOptions, Body, loc(Src, LB, LE))),
        write_data(SI, test_db(TestId, Module, F, A, Dict, TestOptions, Body, loc(Src, LB, LE))),
        fail
    ; true
    ),
    close(SI).

% (extend current options with defaults for ModuleBase)
get_test_options(Options, _, Options) :-
    member(timeout(_,_), Options), !.
get_test_options(Options, ModuleBase, [timeout(_,Timeout)|Options]) :-
    clause_read(ModuleBase, 1, unittest_default_timeout(Timeout), _, _, _, _), !.
get_test_options(Options, _, Options).

split_comp_props([], [], []).
split_comp_props([Comp|Comps0], [Comp|TestOpts], Comps) :- is_texec_comp_prop(Comp), !,
    split_comp_props(Comps0, TestOpts, Comps).
split_comp_props([Comp|Comps0], TestOpts, [Comp|Comps]) :-
    split_comp_props(Comps0, TestOpts, Comps).

% TODO: introduce prepare, cleanup, treat in unittest_runner:testing/5 (around run_test/3)
is_texec_comp_prop(try_sols(_, _)).
is_texec_comp_prop(generate_from_calls_n(_,_)).
is_texec_comp_prop(timeout(_,_)).

:- pred texec_warning(AType, GPProps, Pred, AsrLoc)
    : (atm(AType), list(GPProps), term(Pred), struct(AsrLoc))
  # "A @tt{texec} assertion cannot contain any computational properties
    except @pred{times/2} and @pred{try_sols/2}.  So if a @tt{texec}
    assertion contains any other computational property the corresponding
    test will be generated as if the assertion was of the type
    @tt{test}. The user is notified of this fact by a warning message.
    @var{AType} takes values @tt{texec} and @tt{test}, @var{GPProps}
    is a list of non-ground comp properties, @var{Pred} is a predicate
    from the test assertion and @var{AsrLoc} is the locator of the
    test assertion.".

texec_warning(texec, GPProps, Pred, asrloc(loc(ASource, ALB, ALE))) :-
    \+ GPProps == [], !,
    functor(Pred, F, A),
    maplist(comp_prop_to_name, GPProps, GPNames),
    messages([message_lns(ASource, ALB, ALE, warning, [
        'texec assertion for ', F, '/', A,
        ' can have only unit test commands, ',
        'not comp properties: \n', ''(GPNames),
        '\nProcessing it as a test assertion'])]). % TODO: use message/2?
texec_warning(_, _, _, _).

comp_prop_to_name(C0, C) :- C0 =.. [F, _|A], C =.. [F|A].

:- use_module(library(sets), [ord_subset/2]).
:- use_module(library(terms_vars), [varset/2]).

:- pred check_noexvar_succ(Head, Succ, AsrLoc)
   : (list(Head), list(Succ), struct(AsrLoc))
   # "The success part of a test, @var{Succ}, cannot contain existential
     variables that are not found in the head, @var{Head}.
     The user is notified by means of a warning.".

check_noexvar_succ(Head, Succ,_) :-
    varset(Head, HeadVars),
    varset(Succ, SuccVars),
    ord_subset(SuccVars, HeadVars),
    !.
check_noexvar_succ(Head, _, asrloc(loc(_Src, ALB, ALE))) :-
    functor(Head, PredName, Arity),
    message(warning, ['(lns ', ALB,'-',ALE, ')', ' unexpected existential variables in the success part of ', PredName, '/', Arity]).

:- pred get_test(Module, TestId, Type, Pred, Body, Dict, Src, LB, LE)
    :  atm(Module)
    => atm * atm * unittest_type * term * term * term * atm * int * int
    + non_det
 # "Given a module name @var{Module}, return one test assertion with
  the identifier @var{TestId} with respective assertion parameters
  (assertion body @var{Body}, type @var{Type}, variable dictionary
  @var{Dict}, module source path @var{Src}, start line @var{LB} and
  end line @var{LE}) for a predicate @var{Pred}".

get_test(Module, TestId, Type, Pred, Body, Dict, Src, LB, LE) :-
    current_fact(assertion_read(Pred, Module, check, Type, Body, Dict, Src, LB, LE)),
    unittest_type(Type),
    make_test_id(Module, LB, LE, TestId).

make_test_id(Module,LB,LE,TestId) :-
    atom_number(ALB,LB),
    atom_number(ALE,LE),
    atom_concat([Module,'#',ALB,'#',ALE],TestId).

:- regtype unittest_type/1.
unittest_type(test).
unittest_type(texec).

check_restore_test_input(Module, SelVers) :-
    file_test_input(Module, SelVers, TestInFile),
    ( file_exists(TestInFile) -> true
    ; % TODO: make message optional (currently there is not way to
      %   distinguish between a module without tests and a module whose
      %   tests has not run)
      % message(warning, ['No test results for ', Module]),
      fail  % (fails if no test input)
    ),
    restore_test_input(Module, SelVers).

% Restore test_db from saved file
restore_test_input(Module, Vers) :-
    cleanup_test_db,
    load_test_input(Module, Vers).

% ---------------------------------------------------------------------------
%! # Show test results

:- use_module(library(unittest/unittest_summaries), [
    begin_messages/0, end_messages/0, show_test_result/4
]).

% note: call within a begin_messages/0, end_message/0 context
show_test_res(TestIn, TRes, Opts) :-
    ( get_opt(stdout(dump), Opts) -> ShowOut = yes ; ShowOut = no ),
    ( get_opt(stderr(dump), Opts) -> ShowErr = yes ; ShowErr = no ),
    show_test_result(TestIn, TRes, ShowOut, ShowErr).

% ---------------------------------------------------------------------------
%! # Show and process test summaries

:- reexport(library(unittest/unittest_statistics), [statistical_summary/1, get_statistical_summary/2]).

% Actions process a summary
requires_summary(Actions, Opts) :-
    ( member(status(_), Actions) 
    ; member(summaries(_), Actions)
    ; member(stats(_), Actions)
    ; \+ member(nostats, Opts), member(show_results, Actions)
    ),
    !.

do_summary(Modules, Filter, Actions, SelVers) :-
    get_all_test_outputs(Modules, Filter, SelVers, ModResults),
    ( member(status(TestStatus), Actions) -> get_summary_status(ModResults, TestStatus)
    ; true
    ),
    ( member(stats(Stats), Actions) -> get_statistical_summary(ModResults, Stats)
    ; true
    ),
    ( member(summaries(ModResults2), Actions) -> ModResults = ModResults2
    ; true
    ),
    ( member(show_results, Actions) -> statistical_summary(ModResults)
    ; true
    ).

% (only for modules with testin files)
get_all_test_outputs([], _, _, []).
get_all_test_outputs([Module|Modules], Filter, Vers, ModResults) :-
    file_test_input(Module,Vers,TestInFile),
    ( file_exists(TestInFile) ->
        ModResults = [ModResult|ModResults0],
        get_module_output(Module, Filter, Vers, ModResult)
    ; ModResults = ModResults0 % no testin, probably the module had errors
    ),
    get_all_test_outputs(Modules, Filter, Vers, ModResults0).

% Load test db and test output (for consulting test results without redoing the tests)
load_results(Module, Vers) :-
    restore_test_input(Module, Vers),
    load_test_output(Module, Vers),
    mark_missing_as_aborted(Module).

get_module_output(Module, Filter, Vers, ModResult) :-
    load_results(Module, Vers),
    findall(TInRes,
            get_test_results(Module, Filter, _, TInRes),
            ModResult).

get_test_results(Module, Filter, TestId, TestIn-TestResults) :-
    get_test_in(Module, Filter, TestId, TestIn),
    findall(TRes, test_output_db(TestId, TRes), TestResults).

get_summary_status(ModResults, TestStatus) :-
    get_statistical_summary(ModResults, Stats),
    Stats=stats(NTotal,NSuccess,_,_,_,_,_),
    ( NTotal=NSuccess ->
        TestStatus=0
    ; TestStatus=1
    ).

:- use_module(library(unittest/unittest_runner_common), [
    fill_aborted_test/5,
    next_result_id/2
]).

% Mark all tests with missing output as aborted
% TODO: do dynamically instead (just handle the case of missing test_output_db)
mark_missing_as_aborted(Module) :-
    ( % (failure-driven loop)
      test_db(TestId,Module,_,_,_,_,_,_),
      \+ test_output_db(TestId,_),
        % message(error0, ['log: filling missing as aborted: ', $(TestId-Module)]),
        fill_aborted_test(unknown, aborted, "", "", TRes),
        assertz_fact(test_output_db(TestId, TRes)),
        fail
    ; true
    ).

% ---------------------------------------------------------------------------
%! # Support for regression tests (experimental)

% Note: filters are ignored!
regr_action(Modules, Actions) :-
    ( member(save, Actions) ->
        save_output(Modules) % TODO: no filter allowed
    ; true
    ),
    ( member(briefcompare(ReturnStatus), Actions) ->
        brief_compare(Modules, ReturnStatus)
    ; true
    ),
    ( member(briefcompare, Actions) ->
        brief_compare(Modules, _)
    ; true
    ),
    ( member(compare, Actions) ->
        compare(Modules)
    ; true
    ).

% ---------------------------------------------------------------------------
%! # Run processed tests using the unittest runner

:- use_module(library(system_extra), [mkpath/1]).
:- use_module(library(unittest/unittest_runner), [unittest_runner/2]).

% requires: test_db and get_code_and_related_assertions

check_tests_one_mod(Module, Filter, Opts, SaveRes, ShowRes) :-
    cleanup_test_results,
    %
    ( SaveRes = no -> OutS = none
    ; file_test_output(Module,new,OutFile),
      open(OutFile, write, OutS)
    ),
    %
    ( filtered_test_db(Filter, _, _, _, _, _, _, _, _) ->
        get_test_tmp_dir(TestRunDir),
        cleanup_runner_filedata(TestRunDir),
        mkpath(TestRunDir),
        store_runtest_input(TestRunDir, Filter),
        ( get_opt(rtc_entry, Opts) -> RtcEntry = yes ; RtcEntry = no ),
        create_wrapper_mod(Module, Filter, TestRunDir, RtcEntry, WrapperMod),
        runner_opts(TestRunDir, WrapperMod, Opts, RunnerOpts),
        unittest_runner(RunnerOpts, treat_test_result(Module, Opts, OutS, ShowRes))
    ; true
    ),
    ( OutS = none -> true ; close(OutS) ).

% options for runner
runner_opts(TestRunDir, WrapperMod, Opts, RunnerOpts) :-
    RunnerOpts = [dir(TestRunDir)|RunnerOpts1],
    current_prolog_flag(unittest_default_timeout,TimeoutN),
    RunnerOpts1 = [timeout(TimeoutN)|RunnerOpts2],
    %
    ( opt_suff(Suff) ->
        RunnerOpts2 = [suff(Suff)|RunnerOpts3]
    ; RunnerOpts2 = RunnerOpts3
    ),
    RunnerOpts3 = [wrpmods([WrapperMod])|RunnerOpts4],
    RunnerOpts4 = Opts.

:- pred cleanup_runner_filedata(TestRunDir) : pathname(TestRunDir).
cleanup_runner_filedata(TestRunDir) :-
    % tests directory must exist
    ( file_exists(TestRunDir) ->
        file_runtest_input(TestRunDir, InputFile),
        % tests directory must always contain input files
        ( file_exists(InputFile) -> remove_dir(TestRunDir)
        ; throw(error(existence_error(source_sink,InputFile), cleanup_runner_filedata/1-1))
        )
    ; true % nothing to clean
    ).

get_test_in(Module, Filter, TestId, TestIn) :-
    filtered_test_db(Filter, TestId, Module, F, A, Dict, _, Body, loc(Source, LB, LE)),
    assertion_body(_,_,_,_,_,Comment,Body),
    TestIn = test_in(Module, F, A, Dict, Comment, Source, LB, LE).

treat_test_result(Module, Opts, OutS, ShowRes, TestId, TRes0) :-
    % Save test output (internal db)
    amend_result_id(TestId, TRes0, TRes),
    assertz_fact(test_output_db(TestId, TRes)),
    % Save test output (file)
    ( OutS = none -> true
    ; write_data(OutS, test_output_db(TestId, TRes)),
      flush_output(OutS)
    ),
    % Show results
    ( ShowRes = yes ->
        ( get_test_in(Module, [], TestId, TestIn) ->
            show_test_res(TestIn, TRes, Opts)
        ; message(error, [unknown_test_in(TestId)]) % TODO: this should be a bug
        )
    ; true
    ).

% Amending 'unknown' result_id of aborted tests.
% Do it by recovering last result_id for that TestId and incrementing.
amend_result_id(TestId, TRes0, TRes) :-
    TRes0 = t_res(unknown, RtcErrors, Signal, Result, Stdout, Stderr),
    ( Result = timeout ; Result = aborted ),
    !,
    findall(Id, test_output_db(TestId, t_res(Id,_,_,_,_,_)), Ids),
    ( last(Ids, LastId) ->
        next_result_id(LastId, ResultId)
    ; ResultId = unknown % first one, but we do not know counter limits
    ),
    TRes = t_res(ResultId, RtcErrors, Signal, Result, Stdout, Stderr).
amend_result_id(_TestId, TRes, TRes).

% ---------------------------------------------------------------------------
%! ## Create wrapper modules for test runner

:- use_module(library(formulae), [list_to_conj/2]).
:- use_module(library(llists), [flatten/2]).

% requires: test_db and get_code_and_related_assertions

create_wrapper_mod(Module, Filter, TestRunDir, RtcEntry, WrapperFile) :-
    module_base_path_db(Module,Base,_),
    ( wrapper_file_name(TestRunDir, Module, WrapperFile),
      create_module_wrapper(Module, Filter, RtcEntry, Base, WrapperFile) ->
        true
    ; message(error, ['Failure in create_wrapper_mod/4'])
    ).

% We create module wrappers that contains the test entries from the original source.
% In that way the original modules are not polluted with test code.
create_module_wrapper(Module, Filter, RtcEntry, Src, WrapperFile) :-
    Header = [
        (:- module(_, _, [assertions, nativeprops, rtchecks])),
        (:- include(library(unittest/unittest_wrapper))),
        (:- use_module(Src))
    ],
    collect_test_modules(Src, TestModules),
    % here link the TestEntry clause with the ARef test identifier
    findall(Cls,
            gen_test_entry(Module, Filter, RtcEntry, Src, Cls),
            Clauses),
    %
    Clauses2 = ~flatten([
        raw(Header),
        raw(TestModules),
        raw([(:- push_prolog_flag(single_var_warnings, off))]),
        Clauses,
        raw([(:- pop_prolog_flag(single_var_warnings))])]),
    %
    print_clauses_to_file(WrapperFile, Clauses2).

collect_test_modules(Src) :=
    ~sort(~findall(TestModule, current_test_module(Src, TestModule))).

current_test_module(Src, (:- use_module(TestModule))) :-
    clause_read(Src, 1, load_test_module(TestModule), _, _, _, _).
current_test_module(Src, (:- use_module(TestModule, Predicates))) :-
    clause_read(Src, 1, load_test_module(TestModule, Predicates), _, _, _, _).
current_test_module(Src, (:- use_package(TestModule))) :-
    clause_read(Src, 1, load_test_package(TestModule), _, _, _, _).

% TODO: remove this dependency --NS
:- use_module(library(rtchecks/rtchecks_tr), [collect_assertions/3]).

% TODO: tests abort when the predicate is not defined in the module,
%       fix?  Depends on if we allow tests for imports -- otherwise
%       this code is still useful for writing test assertions of
%       impldef preds such as foreign
gen_test_entry(Module, Filter, RtcEntry, Src, Clauses) :-
    % get current test assertion
    filtered_test_db(Filter, TestId, Module, _, _, ADict, _, ABody, loc(ASource, ALB, ALE)),
    assertion_body(Pred,_,Calls,_,_,_,ABody),
    TestInfo = testinfo(Pred, ABody, ADict, ASource, ALB, ALE),
    % Collect assertions for runtime checking during unit tests:
    %  - none if RtcEntry = no
    %  - none if the module uses rtchecks (already instruments its predicates)
    %  - otherwise, the assertions specified in the original module
    %
    ( (clause_read(Src, 1, rtchecked, _, _, _, _) ; RtcEntry == no) ->
          Assertions = []
    ; collect_assertions(Pred, Module, Assertions)
    ),
    % Get predicate locator for the Pred from the test assertion TestId
    functor(Pred, F, A),
    functor(Head, F, A),
    ( clause_read(Src, Head, _, _, PSource0, PLB, PLE) ->
        bundle_shorten_path(PSource0,PSource),
        PLoc = loc(PSource, PLB, PLE)
    ; PLoc = none
    ),
    % this term is later expanded in the wrapper file by the goal
    % translation of the rtchecks package
    TestBody = '$check_pred_body'(TestInfo, Assertions, PLoc),
    Clauses = [
        clause(test_check_pred(Module, TestId, Pred), TestBody, ADict),
        clause(test_entry(Module,TestId,Pred), ~list_to_conj(Calls), ADict)
    ].

% ---------------------------------------------------------------------------
%! ## Generate modules from terms

:- use_module(library(write), [printq/1]).

% TODO: this code should define portray by default!
:- doc(hide,portray/1).
:- multifile portray/1.
portray('$stream'(Int1, Int2)) :-
    integer(Int1),
    integer(Int2),
    !,
    printq('$stream'(int, int)).
portray(attach_attribute(X, float(V))) :-
    !,
    printq(X), printq('.=.'), printq(V).
portray(rat(A, B)) :- % TODO: for clpq,clpr, should it be here?
    integer(A),
    integer(B),
    !,
    printq(A/B).

:- use_module(library(varnames/apply_dict), [apply_dict/3]).
:- use_module(library(write), [write/1, writeq/1]).

% (exported)
print_clauses_to_file(Path, Clauses) :-
    open(Path, write, IO),
    print_clauses(Clauses, IO),
    close(IO).

print_clauses([], _IO).
print_clauses([C|Cs], IO) :- print_clause(C, IO), print_clauses(Cs, IO).

print_clause(raw(Clauses), IO) :-
    unittest_print_clauses(Clauses, IO, []).
print_clause(clause(Head, Body, Dict), IO) :-
    unittest_print_clause(IO, Dict, (Head :- Body)).

unittest_print_clause(S, Dict, Term) :-
    apply_dict(Term, Dict, ATerm),
    current_output(CO),
    set_output(S),
    writeq(ATerm),
    write(' .'),
    nl,
    set_output(CO).
%       portray_clause(S, ATerm).

unittest_print_clauses(Term, S, Dict) :-
    current_output(CO),
    set_output(S),
    maplist(unittest_print_clause(S, Dict), Term),
    set_output(CO).
