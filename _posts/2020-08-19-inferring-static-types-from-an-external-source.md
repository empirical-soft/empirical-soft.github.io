---
title: "Inferring static types from an external source"
include_title: true
---

Empirical is a language for time-series analysis. Uniquely, it has statically typed Dataframes whose types can be inferred from an external source at compile time.

```
>>> let trades = load("trades.csv")

>>> trades
 symbol                  timestamp    price size
   AAPL 2019-05-01 09:30:00.578802 210.5200  780
   AAPL 2019-05-01 09:30:00.580485 210.8100  390
    BAC 2019-05-01 09:30:00.629205  30.2500  510
    CVX 2019-05-01 09:30:00.944122 117.8000 5860
   AAPL 2019-05-01 09:30:01.002405 211.1300  320
   AAPL 2019-05-01 09:30:01.066917 211.1186  310
   AAPL 2019-05-01 09:30:01.118968 211.0000  730
    BAC 2019-05-01 09:30:01.186416  30.2450  380
    CVX 2019-05-01 09:30:01.639577 118.2550 2880
    BAC 2019-05-01 09:30:01.867638  30.2450  260
   AAPL 2019-05-01 09:30:02.065535 211.1800  260
    BAC 2019-05-01 09:30:02.118224  30.2600  300
    CVX 2019-05-01 09:30:02.260710 118.3100 1450
    BAC 2019-05-01 09:30:02.379882  30.2650  300
   AAPL 2019-05-01 09:30:02.422211 211.3300  270
    CVX 2019-05-01 09:30:02.439735 118.2900  760
    CVX 2019-05-01 09:30:02.869668 118.2700  980
    BAC 2019-05-01 09:30:02.987527  30.2350  220
   AAPL 2019-05-01 09:30:03.057945 211.4425  300
    CVX 2019-05-01 09:30:03.363338 118.5100  990
    ...                        ...      ...  ...

>>> columns(trades)
symbol: String
timestamp: Timestamp
price: Float64
size: Int64
```

Empirical uses a set of metaprogramming techniques to infer the types. Here is the actual definition of the `load()` function, written in Empirical:

```
data CsvProvider{filename: String} = compile(_csv_infer(filename))

func csv_load{T}(filename: String) -> !T => _csv_load(filename, !T)

func load($ filename: String) => csv_load{CsvProvider{filename}}(filename)
```

And here is the `store()` function:

```
func store(df, filename: String) => _csv_store(type_of(df), df, filename)
```

This post will cover what the various symbols above mean, and we will see how Empirical's own features make type inferencing possible.

### Virtual machine

As with many languages, Empirical runs on top of a virtual machine, known as Vector Virtual Machine (VVM). Empirical will show assembly code of what it is doing with `--dump-vvm`. A simple assignment like:

```
>>> var x = 5
```

becomes an instruction to VVM:

```
assign 5 i64s @1
```

This assigns the number `5`, which is a 64-bit integer scalar (`i64s`), to the global register `@1`.

An expression like:

```
>>> x * 17
```

becomes:

```
mul_i64s_i64s @1 17 %0
```

This multiplies the `x` register and the number `17`, both of which are of type `i64s`. The result is stored in a temporary/local register `%0`, whose contents will be displayed on the console back to the user.

As the name implies, VVM is vector-aware. Most operations support vector actions. For example:

```
>>> x * [13, 17, 23]
```

becomes:

```
alloc i64v %2
append 13 i64s %2
append 17 i64s %2
append 23 i64s %2
mul_i64s_i64v @1 %2 %3
```

The code allocates a 64-bit integer vector (`i64v`) in local register `%2`. It then appends the scalar values one-by-one. Finally, it multiplies the original `x` (of type `i64s`) and the temporary vector (of type `i64v`), storing the result in `%3`.

Empirical has two instances of VVM: one for runtime scheduling and one for compile-time ("comptime") scheduling.

### Compile-time function evaluation

Consider this simple assignment:

```
>>> var y = 43 + 27
```

This is compiled to:

```
assign 70 i64s @2
```

Notice how the `43 + 27` became `70`? Empirical decided that `y`'s value could be determined entirely at compile time. (We'll get into *how* it decides that a little later.) So Empirical ran the expression on the comptime VVM and scheduled only the result on the runtime VVM.

This feature is commonly known as compile-time function evaluation (CTFE), and Empirical is pretty aggressive about using it. CTFE occurs automatically and happens over any expression whose result (1) can be determined at comptime, and (2) produces a *literal* value. Empirical employs CTFE over array indices, user-define types and functions, and any other kind of expression.

### compile()

Empirical needs CTFE for the related `compile()` function, which injects a user's `String` value into the compiler. For example:

```
>>> var z = compile("x + y")
```

becomes:

```
add_i64s_i64s @1 @2 @3
```

If we had instead used the declaration:

```
>>> var z = compile("5 + 3")
```

we would have gotten:

```
assign 8 i64s @3
```

The `compile()` function requires that the string be known at comptime. So this is fine:

```
>>> compile("print(x)")
```

but this is not:

```
>>> var my_string = "print(x)"

>>> compile(my_string)
```

We get the following error:

```
Error: compile() requires a comptime string
```

### Mutability

The `var` declaration indicates that a variable is *mutable*, meaning that it can change during runtime. Because of that, the actual value of a `var` is not useable for CTFE; only the register that it maps to can be used in the generated instructions for VVM.

Instead, we can tell Empirical that a value will be constant:

```
>>> let a = 42
```

This generates no instructions for the runtime VVM! Instead, the Empirical compiler simply holds onto the value until it is needed later. This allows for some interesting tricks:

```
>>> let f = "print"

>>> let v = "x"

>>> compile(f + "(" + v + ")")
```

The resulting instruction is now as we would expect:

```
print_i64s @1
```

### Function traits and computation modes

This brings us back to the question of how Empirical decides that a value can be determined at comptime. The answer is that Empirical tracks how every expression operates, meaning that the compiler knows, for example, when an expression has a side effect (eg., IO or global variables) and when an expression is pure (purely functional, from a computer science standpoint).

The mechanism is known as *function traits*, which complement the type system. A trait is a positive quality about a function, such as the function is commutative over its arguments, or that a function returns a vector the same size as its input. A function can have multiple traits.

The trait we are concerned with in this post is `pure`.

A related concept is *computation mode*. Ordinarily we think of user code running as we see it (`Normal` mode), but we can imagine re-ordering the sequence of steps, like in lazy evaluation.

The mode we are concerned with is `Comptime`.

If a type tells us the kind of data, then the traits and mode tell us the kind of computation. And the rules are pretty straightforward:

 1. Most of VVM's operators have a `pure` trait, with the obvious exceptions such as IO, clock access, and random-number generation.
 2. All literal values (eg., `5`, `"cat"`, `true`) are both `Comptime` and `pure`.
 3. Variables declared with `let` inherit traits & mode from the assigned expression; `var` is always `Normal` and has no traits.
 4. A function is `pure` iff all expressions in the function are `pure`.
 5. If a `pure` function is applied to all `pure` parameters, then the result is `pure`.
 6. If a `pure` function is applied to all `Comptime` parameters, then the result is `Comptime`.

So as long as a variable is declared with `let` and there are no impure operations (IO, etc.), the value will be `Comptime`.

```
>>> traits_of(x + 7)
none

>>> mode_of(x + 7)
Normal

>>> traits_of(a + 7)
pure, transform, linear

>>> mode_of(a + 7)
Comptime
```

### Templates

Empirical has user-defined types and functions, like every language.

```
data Person:
  name: String,
  age: Int64
end

func who_is(p: Person):
  return p.name + " is " + String(p.age) + " years old"
end
```

The above is in *statement syntax*; Empirical also allows *expression syntax*.

```
data Person = {name: String, age: Int64}

func who_is(p: Person) = p.name + " is " + String(p.age) + " years old"
```

Both types of syntax allow *templates*. Empirical uses squiggly braces (`{}`) instead of angle brackets (`<>`) because they are much easier to parse.

```
>>> data Person{AgeType}: name: String, age: AgeType end

>>> Person{Int64}("A", 1)
 name age
    A   1

>>> Person{Float64}("A", 1.1)
 name age
    A 1.1

>>> func who_is{T}(p: T) = p.name + " is " + String(p.age) + " years old"

>>> let p = Person{Int64}("A", 1)

>>> who_is{type_of(p)}(p)
"A is 1 years old"
```

### Type providers

A *type provider* is a way of programmatically defining a type. Empirical does this by combining templates and `compile()`. First, consider VVM's `_csv_infer()` function:

```
>>> _csv_infer("trades.csv")
"{symbol: String, timestamp: Timestamp, price: Float64, size: Int64}"
```

This samples the first 10 lines of a CSV file and returns a `String` of the inferred type. VVM actually cheats here since `_csv_infer()` is listed as `pure`, but we can get away with it since the parameter must be `Comptime` for the type provider to work anyway.

Now we are ready to revisit our first line of Empirical code from the top:

```
data CsvProvider{filename: String} = compile(_csv_infer(filename))
```

This takes a *value template* (as opposed to a type template). Templates must be given a comptime literal, so CTFE is invoked automatically on the parameter:

```
>>> CsvProvider{"trades" + ".csv"}
<type: CsvProvider{"trades.csv"}>
```

The resulting type is inferred at compile time!

### Dataframes

It's worth taking a brief segue here to discuss how Empirical handles Dataframes. As with most analytics platforms, each column in Empirical is just a vector. A simple type can be converted to a Dataframe type by prepending it with an exclamation point (`!`).

```
>>> let p = !Person{Int64}(["A", "B", "C"], [1, 2, 3])

>>> p
 name age
    A   1
    B   2
    C   3

>>> p.age
[1, 2, 3]
```

Now we can begin to understand the second statement from the top. Here is a similar line:

```
func csv_load{T}(filename: String) = _csv_load(filename, !T)
```

VVM's `_csv_load()` needs to know the type to use when reading a file. We simply supply it with the Dataframe type from the template (`!T`). 

Also, we must note that while Empirical can usually infer the return type from a function definition, that doesn't work here. VVM's `_csv_load()` can return any type, so Empirical must list it explicitly with the single arrow (`->`):

```
func csv_load{T}(filename: String) -> !T = _csv_load(filename, !T)
```

We can now call this function to get our Dataframe.

```
>>> csv_load{CsvProvider{"trades.csv"}}("trades.csv")
```

### Macros

Listing `"trades.csv"` twice is kind of annoying. Fortunately, we can use a *macro* to shorten it simply by prepending a dollar sign (`$`) to any parameter. Empirical's macros are syntactic sugar for templates; the function:

```
foo($ a: Int64, b: Int64)
```

is really just:

```
foo{a: Int64}(b: Int64)
```

The macro parameter, as with any template value parameter, must be a comptime literal.

Our third line of Empirical from the top is similar to:

```
func load($ filename: String) = csv_load{CsvProvider{filename}}(filename)
```

This is much more convenient.

### Inline functions

Let's consider how VVM handles user-defined functions. This example:

```
>>> func inc(x: Int64) = x + 1

>>> inc(8)
```

becomes:

```
@4 = def inc("x": i64s) i64s:
  add_i64s_i64s %0 1 %1
  ret %1
end

call @4 2 8 %11
```

The `inc()` function takes an `i64s` (called `x`) and returns an `i64s`. This function is assigned to global register `@4`. When we call it, we must pass two (`2`) parameters: the input (`8`) and the location of the output (local/temporary register `%11`).

This works pretty well, but it's a lot of overhead for such a simple routine. Fortunately, Empirical has *inline functions*, which are forced via the double arrow (`=>`):

```
>>> func inc(x: Int64) => x + 1

>>> inc(8)
```

The entire result is:

```
add_i64s_i64s 8 1 %11
```

And with that, we now have our full two lines from the top:

```
func csv_load{T}(filename: String) -> !T => _csv_load(filename, !T)

func load($ filename: String) => csv_load{CsvProvider{filename}}(filename)
```

### Generics

Templates are great, but they require supplying the type explicitly.

```
>>> func add{T}(a: T, b: T) => a + b
```

As with macros, we have some syntactic sugar in the form of *generics*. By omitting the parameters type, we tell Empirical to derive the type based on the caller:

```
>>> func add(a, b) => a + b

>>> add(4, 5)
9

>>> add("Hello ", "World")
"Hello World"
```

Not all parameters need to be generic or specified; users can mix and match as desired. That leads us to our final line from the top:

```
func store(df, filename: String) => _csv_store(type_of(df), df, filename)
```

This invokes VVM's `_csv_store()` with the type of the Dataframe.

### Putting it all together

By combining a virtual machine, CTFE, traits & modes, templates, macros, generics, and inlining, we can define type-specializing code in Empirical itself.

From a fresh Empirical instance:

```
>>> let trades = load("trades.csv")

>>> store(trades, "trades2.csv")
```

becomes:

```
$0 = {"symbol": Sv, "timestamp": Tv, "price": f64v, "size": i64v}

@2 = "trades.csv"
@3 = "trades2.csv"

load @2 $0 @1
store $0 @1 @3
```

The `trades` variable is mapped to `@1`, the inferred type is listed in type definition `$0`, and the strings are internalized as `@2` and `@3`.
