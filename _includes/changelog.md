#### 0.6.9	(2020-12-23)

- Fix for GitHub Actions: include the version number in the built binary

#### 0.6.8	(2020-12-22)

- Migrated CI to GitHub Actions

#### 0.6.7	(2020-09-14)

- Added `mean()`, `variance()`, and `stddev()`
- Added `len()` and `reverse()` for `String`

#### 0.6.6	(2020-08-31)

- Fixed bug where a user error in the REPL caused global variables to fail

#### 0.6.5	(2020-08-25)

- Fixed bug when overloading placeholder generics

#### 0.6.4	(2020-08-24)

- Fixed bug in how generic placeholders work with inferred Dataframe types

#### 0.6.3	(2020-08-23)

- Added `reverse()` and `len()`
- Added generic placeholders
- Added quick documentation in REPL via `?`
- Suspend REPL with Ctrl-Z (POSIX)

#### 0.6.2	(2020-08-20)

- Added generic form of `String()` and `print()`
- Added specialization of generic functions

#### 0.6.1	(2020-08-19)

- Fixed bug regarding constructors on data expressions

#### 0.6.0	(2020-08-17)

- Migrated `load$()` to `load()`
- Added macros
- Added `exit()` and `argv`
- Added int-to-float operators

#### 0.5.6	(2020-08-14)

- Added inline functions
- Fixed bugs on global variables

#### 0.5.5	(2020-08-11)

- Added expression syntax for types and functions
- Types no longer have to be upper case (though still a good idea)

#### 0.5.4	(2020-08-08)

- Added generic functions

#### 0.5.3	(2020-08-07)

- Added templates for data definitions
- Much faster CTFE

#### 0.5.2	(2020-08-06)

- Added type parameters for templates
- Fixed bug when using templates in REPL

#### 0.5.1	(2020-08-05)

- Added function templates for literals
- Fixed bug in how local variables are handled during CTFE

#### 0.5.0	(2020-08-03)

- Added `compile()` function
- Added compile-time function evaluation (CTFE)
- Added function traits and computation modes
- Prohibit reassignment of immutable variables

#### 0.4.2	(2020-05-26)

- Added `type_of()` and `columns()`

#### 0.4.1	(2020-05-23)

- Can handle pre-epoch timestamps

#### 0.4.0	(2020-05-22)

- Added trig functions
- Fixed bug on nested query/join/sort

#### 0.3.0	(2019-05-31)

- Enabled automated deploy

#### 0.2.0	(2019-05-30)

- Set-up continuous integration
- Fixed parsing bugs
- Added modulo operator

#### 0.1.0	(2019-05-20)

- Initial release

