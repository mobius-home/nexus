# Contributing

Nexus server has a few "different" parts to it and this document is to outline
some expectations and patterns in the project to help get your PR merged.

## General Nexus practices

As with all "practices" there are times to break or bend them, but this section
covers the general code and PR expectations in Nexus. If you're newer to any of
this we highly encourage you to contribute and would be more than happy to help
walk through any questions you have in regards to these. Either do your best with
the PR and we can cover topics as needed in the review or open an issue and ask
some questions. Remember, we all started somewhere and those of us who have
been doing this for a bit still don't know as much as we let on. With Nexus your
in good company!

### Try to keep PRs small and focused

We appreciate your PRs and we want to get them merged. The fastest way do this
is to keep them as small and focused as possible. A good example of this is when
you're working on a feature and see a way move code around to reduce
duplication, so you refactor the code to be better and you go along with your
feature implementation. While the improvement is much appreciated, this might
take longer to review depending on the scope of the changes. Another approach
would be to submit a PR for the refactoring and mention the feature you're
working on in the PR. Then make a follow up PR that implements the feature.

Now there is some gray areas here, so it's not as plain as separate out all PRs.
Moreover, this is just advice to get your PRs in quickly. We'd hate for your
awesome refactoring to be blocked due to any comments in the feature
implementation.

Lastly, following the remaining practices will help get your PRs in quicker, so 
be sure to read on.

### Documentation

Please document all non `defp` functions and `@moduledoc` all modules. Default
to `@moduledoc false` if the module isn't used outside the context. If you're
changing documentation (adding, removing, changing functions, types, or modules)
please run `mix docs` and check out your changes to make sure everything is
okay. Also, in `mix.exs` we try to give all modules a well defined place to live
in the documentation, so if you add or remove a module please ensure that the
`docs/0` function in the `mix.exs` is updated accordingly.

Also, as you see missing docs or docs that can be updated (spelling, grammar,
content, etc.) feel free to make a PR. These types of PRs are extremely helpful.

### Types

Yes, we know there are mix opinions about dialyzer and types in Elixir. We made
the choice to go all in on types and we ask you help up in this effort. Also, in
the same way we documentation for modules and functions, Nexus values
documentation for types and are expected. If a function is `def` please ensure a
`@spec` is defined with well defined types. The pattern for defining a type is as
follows:

```elixir
@typedoc """
A help note about what this type is

If there is any special considerations please note them here.
"""
@type my_type() :: binary()
```

While the above type alias is trivial please note there is type doc and the `()`
at the end of the type name. Also, prefer to use `binary()` over `String.t()`
when type aliasing strings.

Also, as you see missing typespecs or typedocs that can be updated (spelling,
grammar, content, correctness, etc.) feel free to make a PR. These types of PRs
are extremely helpful.

### Tests

Test as much that is in reason. Getting 100% test coverage is not a goal with
Nexus. However, we do want to write as many tests where it makes sense. A good
question to ask when writing a test is, "am I just testing functions from
another library?"


### Local is preferred

When it comes to some items such as plugs and types, we should opt for the most
local place to the code that uses or defines it. Sometimes, it does not make
more sense to pull stuff to a higher layer, but at least a first pass to localize
these things is nice. This can lead to a little duplication and that is okay.
Sometimes it is easier to maintain a little duplication that it is a broken
abstraction.

This really falls into the "general rule" category and can be ignored often. We
want be mindful of call indirection to lines of code ratio. If the self imposed
indirection is many layers deep for code that is 2-4 lines, it might be best to
duplicate is some cases.

## Design Patterns

In a few ways Nexus code implementation is unique. Both by adopting some 
non-mainstream Phoenix conventions and due to the nature of problem Nexus is
trying to solve. Where possible we try to document these things as best as
possible.

### Request params

Inspired by [Towards Maintainable Elixir: The Core and the Interface](https://medium.com/very-big-things/towards-maintainable-elixir-the-core-and-the-interface-c267f0da43)
by Sasa Juric, Nexus uses `Ecto.Changeset` to validate incoming request params.
This allows us to develop the `Nexus` library separate from the demands of the
interface and we can put request validations at the interface layer and database
validations in the core `Nexus` layer.

The module `NexusWeb.RequestParams` contains a protocol that will allow the
controller to bind the incoming params to a known data structure that can be
well documented and tested. This is opposite of passing `map()` to all context
functions. The idea of binding comes from Go's Gin web framework, you can read
more about it [here](https://chenyitian.gitbooks.io/gin-web-framework/content/docs/17.html).

We know this is different, but we hope as this area of the code evolves it will
help maintainability long term.

### Database design

Nexus uses Timescale DB, which is an extension for time series data on top of
PostgreSQL. There are many reasons for choosing this database but two we find
really compelling is:

At the end of the day it is just Postgres with some extra functionality. This
allows quicker knowledge transfer for developers, admins, and ops teams coming
from Postgres. All that hard earned experience can be applied to Timescale.

Since it is just Postgres, it can operate as both the time series database and
as the application database.

#### Dynamic hypertables

Timescale provides us with functionality for something they call hypertables.
These are special tables that are built to handle the unique demands of time
series data both for ingestion and querying.

When you create a new product in Nexus, it will be given its only schema for
these hypertables in the form of `<product_name>_data`. In this schema, as a new
metric is added a product we generate a table by the metric's name in this
schema and set some rules on it to help with the loose time ordering metrics are
pushed from devices.

Some of the ideas found in this implementation where inspired by the
[promscale](https://docs.google.com/document/d/1e3mAN3eHUpQ2JHDvnmkmn_9rFyqyYisIgdtgd3D1MHA/edit#)
design document provided by Timescale.

