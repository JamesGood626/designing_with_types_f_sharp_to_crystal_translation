# email_address : String
# state : String
# zip : String

# ^^ These aren't interchangable.
# In Domain Driven Design, they are indeed distinct things,
# not just strings.

# SOLUTION:
# Ideally, we'd like to have separate types for them so
# that they cannot accidentally be mixed up.


# This has been known as good practice for a long time, but in languages like C# and
# Java it can be painful to create hundred of tiny types like this, leading to the so
# called “primitive obsession” code smell.
# 
# https://sourcemaking.com/refactoring/smells/primitive-obsession

# The simplest way to create a separate type is to wrap the underlying
# string type inside another type.

# We can use single case union types:
alias EmailAddress = String
alias ZipCode = String
alias StateCode = String

# Alternatively, we could use record types with one field:
# In Crystal I do think there's a macro that allows for a more terse syntax.
struct EmailAddress
    def initialize(@email_address : String) end
end

struct ZipCode
    def initialize(@zip_code : String) end
end

struct StateCode
    def initialize(@state_code : String) end
end

# In the blog post, he recommends using the single case union instead of a record.
# BUT he's using F#, where the union has a constructor:
# // using the constructor as a function
# "a" |> EmailAddress

# ^^ Crystal's Unions don't have this, and serve only as an alias, which won't
# really allow us to distinguish between the strings.

# In Crystal, with the struct approach, we get a constructor AND can perform
# validation on the provided input in each of the constructors.

# Then you'll just need to use pattern matching to unwrap the string.

# The code from part_one.cr refactored to make use of the Wrapper types:

struct PersonalName
    def initialize(
        @first_name : String,
        @middle_initial : String?,
        @last_name : String,) end
end

struct EmailAddress
    def initialize(@email_address : String) end
end

struct EmailContactInfo
   def initialize(
      @email_address : EmailAddress,
      @is_email_verified : Bool,) end
end

struct ZipCode
    def initialize(@zip_code : String) end
end

struct StateCode
    def initialize(@state_code : String) end
end

struct PostalAddress
    def initialize(
      @address_one : String,
      @address_two : String,
      @city : String,
      @state : ZipCode,
      @zip : StateCode, ) end
end
  
struct PostalContactInfo
  def initialize(
    @address : PostalAddress,
    @is_address_valid : Bool, ) end
end

struct Contact
  def initialize(
    @name : PersonalName,
    @email_contact_info : EmailContactInfo,
    @postal_contact_info : PostalContactInfo, ) end
end

# Running validation at construction time (once the value is constructed it's immutable
# so there's no worry that someone might modify it later):
# ... types as above ...

# let CreateEmailAddress (s:string) =
#     if System.Text.RegularExpressions.Regex.IsMatch(s,@"^\S+@\S+\.\S+$")
#         then Some (EmailAddress s)
#         else None

# let CreateStateCode (s:string) =
#     let s' = s.ToUpper()
#     let stateCodes = ["AZ";"CA";"NY"] //etc
#     if stateCodes |> List.exists ((=) s')
#         then Some (StateCode s')
#         else None

# With these kinds of constructor functions, one immediate challenge is the
# question of how to handle invalid input:
# 1. Throw an exception (ugly and unimaginative, so won't be doing this)
# 2. Return an option type, with None meaning that the input was invalid (this is
#    what the constructor functions above do).

# #2 is generally the easiest approach + it has the advantae that the caller
# has to explicitly handle the case when the value is not valid.

# For example, the caller's code might look like:
# match (CreateEmailAddress "a@example.com") with
# | Some email -> ... do something with email
# | None -> ... ignore?

# ENTER THE EITHER/RESULT TYPE
# The disadvantage is that with complex validations, it might not be obvious what
# went wrong (was the email too long, missing a '@' sign, or an invalid domain?).

# type EmailAddress = EmailAddress of string
# type CreationResult<'T> = Success of 'T | Error of string

# let CreateEmailAddress2 (s:string) =
#     if System.Text.RegularExpressions.Regex.IsMatch(s,@"^\S+@\S+\.\S+$")
#         then Success (EmailAddress s)
#         else Error "Email address must contain an @ sign"

# // test
# CreateEmailAddress2 "example.com"

# 3. The most general approach uses continuations (the user pass in two functions,
#    one for the success case that takes the newly constructed email as a parameter,
#    and another for the failure case that takes the error string as a parameter).

# type EmailAddress = EmailAddress of string

# let CreateEmailAddressWithContinuations success failure (s:string) =
#     if System.Text.RegularExpressions.Regex.IsMatch(s,@"^\S+@\S+\.\S+$")
#         then success (EmailAddress s)
#         else failure "Email address must contain an @ sign"

# let success (EmailAddress s) = printfn "success creating email %s" s
# let failure  msg = printfn "error creating email: %s" msg
# CreateEmailAddressWithContinuations success failure "example.com"
# CreateEmailAddressWithContinuations success failure "x@example.com"

# With continuations, you can easily reproduce any of the other approaches.

# Here's the way to create options (in this case both functions return an EmailAddress option):
# let success e = Some e
# let failure _  = None
# CreateEmailAddressWithContinuations success failure "example.com"
# CreateEmailAddressWithContinuations success failure "x@example.com"

# And here is the way to throw exceptions in the error case:
# let success e = e
# let failure _  = failwith "bad email address"
# CreateEmailAddressWithContinuations success failure "example.com"
# CreateEmailAddressWithContinuations success failure "x@example.com"

# CREATE A PARTIALLY APPLIED FUNCTION:
# This code seems quite cumbersome, but in practice you would probably create
# a local partially applied function that you use instead of the long-winded one.

# // setup a partially applied function
# let success e = Some e
# let failure _  = None
# let createEmail = CreateEmailAddressWithContinuations success failure

# // use the partially applied function
# createEmail "x@example.com"
# createEmail "example.com"

# https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/#creating-modules-for-wrapper-types
# ^^ Can just use Crystal's Structs for this

# https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/#forcing-use-of-the-constructor
# ^^ Also not a concern when using Crystal's structs (because the only way to instantiate one is via the .new method)

######################################
# When to "wrap" single case union:
######################################
# Now that we have the wrapper type, when should we construct them?

# Generally you only need to at service boundaries (for example,
# boundaries in a hexagonal architecture)

# As part of the construction, it is critical that the caller uses the provided constructor
# rather than doing its own validation logic. This ensures that “bad” values can never
# enter the domain.

# For example, here is some code that shows the UI doing its own validation:

# let processFormSubmit () =
#     let s = uiTextBox.Text
#     if (s.Length < 50)
#         then // set email on domain object
#         else // show validation error message

# A better way is to let the constructor do it, as shown earlier.

# let processFormSubmit () =
#     let emailOpt = uiTextBox.Text |> EmailAddress.create
#     match emailOpt with
#     | Some email -> // set email on domain object
#     | None -> // show validation error message

######################################
# When to "unwrap" single case union:
######################################
# And when is unwrapping needed? Again, generally only at service boundaries.
# For example, when you are persisting an email to a database, or binding to
# a UI element or view model.

# One tip to avoid explicit unwrapping is to use the continuation approach again.

# That is, rather than calling the “unwrap” function explicitly:

# address |> EmailAddress.value |> printfn "the value is %s"
# You would pass in a function which gets applied to the inner value, like this:

# address |> EmailAddress.apply (printfn "the value is %s")

# Putting this together, we now have the complete EmailAddress module.

# module EmailAddress =

#     type _T = EmailAddress of string

#     // create with continuation
#     let createWithCont success failure (s:string) =
#         if System.Text.RegularExpressions.Regex.IsMatch(s,@"^\S+@\S+\.\S+$")
#             then success (EmailAddress s)
#             else failure "Email address must contain an @ sign"

#     // create directly
#     let create s =
#         let success e = Some e
#         let failure _  = None
#         createWithCont success failure s

#     // unwrap with continuation
#     let apply f (EmailAddress e) = f e

#     // unwrap directly
#     let value e = apply id e


###################
# The Code So Far
###################
# Let’s refactor the Contact code now, with the new wrapper types and modules added.

# module EmailAddress =

#     type T = EmailAddress of string

#     // create with continuation
#     let createWithCont success failure (s:string) =
#         if System.Text.RegularExpressions.Regex.IsMatch(s,@"^\S+@\S+\.\S+$")
#             then success (EmailAddress s)
#             else failure "Email address must contain an @ sign"

#     // create directly
#     let create s =
#         let success e = Some e
#         let failure _  = None
#         createWithCont success failure s

#     // unwrap with continuation
#     let apply f (EmailAddress e) = f e

#     // unwrap directly
#     let value e = apply id e

# module ZipCode =

#     type T = ZipCode of string

#     // create with continuation
#     let createWithCont success failure  (s:string) =
#         if System.Text.RegularExpressions.Regex.IsMatch(s,@"^\d{5}$")
#             then success (ZipCode s)
#             else failure "Zip code must be 5 digits"

#     // create directly
#     let create s =
#         let success e = Some e
#         let failure _  = None
#         createWithCont success failure s

#     // unwrap with continuation
#     let apply f (ZipCode e) = f e

#     // unwrap directly
#     let value e = apply id e

# module StateCode =

#     type T = StateCode of string

#     // create with continuation
#     let createWithCont success failure  (s:string) =
#         let s' = s.ToUpper()
#         let stateCodes = ["AZ";"CA";"NY"] //etc
#         if stateCodes |> List.exists ((=) s')
#             then success (StateCode s')
#             else failure "State is not in list"

#     // create directly
#     let create s =
#         let success e = Some e
#         let failure _  = None
#         createWithCont success failure s

#     // unwrap with continuation
#     let apply f (StateCode e) = f e

#     // unwrap directly
#     let value e = apply id e

# type PersonalName =
#     {
#     FirstName: string;
#     MiddleInitial: string option;
#     LastName: string;
#     }

# type EmailContactInfo =
#     {
#     EmailAddress: EmailAddress.T;
#     IsEmailVerified: bool;
#     }

# type PostalAddress =
#     {
#     Address1: string;
#     Address2: string;
#     City: string;
#     State: StateCode.T;
#     Zip: ZipCode.T;
#     }

# type PostalContactInfo =
#     {
#     Address: PostalAddress;
#     IsAddressValid: bool;
#     }

# type Contact =
#     {
#     Name: PersonalName;
#     EmailContactInfo: EmailContactInfo;
#     PostalContactInfo: PostalContactInfo;
#     }

# # SUMMARY:
# Do use single case discriminated unions to create types that represent the domain accurately.
# If the wrapped value needs validation, then provide constructors that do the validation and enforce their use.
# Be clear what happens when validation fails. In simple cases, return option types. In more complex cases, let the caller pass in handlers for success and failure.
# If the wrapped value has many associated functions, consider moving it into its own module.
# If you need to enforce encapsulation, use signature files.

# # !!!!!!!!!!!!!
# We’re still not done with refactoring. We can alter the design of types to enforce business rules at compile time – making illegal states unrepresentable.



# Update
# Many people have asked for more information on how to ensure that constrained types such as EmailAddress are only created through a special
# constructor that does the validation. So I have created a gist here that has some detailed examples of other ways of doing it.
# https://gist.github.com/swlaschin/54cfff886669ccab895a