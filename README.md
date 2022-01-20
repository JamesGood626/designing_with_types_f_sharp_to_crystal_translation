# Basic Crystal Reminders

# 1. Simple iteration over each element of an array
```
[1, 2, 3].each { |x| puts x }
```

NOTE: A more complicated type used in the array requires a type spec in the lambda
```
contact_info.contact_methods.each { |contact_method : ContactMethod| { print_contact_method(contact_method) } } 
```

# 2. Some simple HashMap and Array operations
id = "#rand"
m = {id => 100}
m["#rand.a"] = 200
puts m

xs = [1,2,3]
puts "x[0] is #{xs[0]}"
puts "x[1..2] is #{xs[1..2]}"
puts xs.size

OUTPUT:
{"#rand" => 100, "#rand.a" => 200}
x[0] is 1
x[1..2] is [2, 3]
3


# IMPORTANT NOTE:
The concepts discussed in part_two.cr are intractable (when using a union type that has more than one Tuple case)

```
Run #cbe5
Code
  
struct Action  
  def initialize(@id : String) end
end
 
struct Guard  
  def initialize(@id : String) end
end
 
# alias TransitionTo = String
struct TransitionTo
    def initialize(@id : String) end
end
 
alias Actions = Array(Action)
alias Guards = Array(Guard)
 
alias Effects =
  TransitionTo                 |
  Actions                      |
  Guards                       |
  Tuple(TransitionTo, Guards) |
  Tuple(TransitionTo, Actions) |
  Tuple(Actions, Guards)       |
  Tuple(TransitionTo, Actions, Guards)
 
struct Transition
  getter effects
  
  def initialize(@effects : Effects) end
  
  def transition_to()
    get_transition_to(self.effects)
  end
end
 
def get_transition_to(x : TransitionTo)
	x
end
 
def get_transition_to(t : Tuple(TransitionTo, Actions | Guards))
  t[0]
end
  
def get_transition_to(t : Tuple(TransitionTo, Actions, Guards))
   t[0]
end
 
   def get_transition_to(a : Actions)
    nil  
  end
  
   def get_transition_to(g : Guards)
    nil  
  end
  
  def get_transition_to(t : Tuple(Actions, Guards))
    nil  
  end
 
  
puts "typeof({TransitionTo.new('show_flop'), [Guard.new('max_retries_not_exceeded')]}): #{typeof({TransitionTo.new("show_flop"), [Guard.new("max_retries_not_exceeded")]})}"
 
t = Transition.new({TransitionTo.new("show_flop"), [Guard.new("max_retries_not_exceeded")]})
 
puts t.transition_to
```

OUTPUT:
error in line 32
Error: no overload matches 'get_transition_to' with type (Array(Action) | Array(Guard) | TransitionTo | Tuple(Array(Action) | TransitionTo, Array(Action) | Array(Guard)) | Tuple(TransitionTo, Array(Action), Array(Guard)))

Overloads are:
 - get_transition_to(x : TransitionTo)
 - get_transition_to(t : Tuple(TransitionTo, Actions | Guards))
 - get_transition_to(t : Tuple(TransitionTo, Actions, Guards))
 - get_transition_to(a : Actions)
 - get_transition_to(g : Guards)
 - get_transition_to(t : Tuple(Actions, Guards))

 The type above spaced out...
(
    Array(Action) |
    Array(Guard) |
    TransitionTo |
    Tuple(
        Array(Action) | TransitionTo, Array(Action) | Array(Guard)
    )
    | Tuple(
        TransitionTo, Array(Action), Array(Guard))
    )


# This model is broken when working with the TransitionBuilder...
# The fiber/thread explanation is a solid reason for why it doesn't match what I had in mind:
# https://forum.crystal-lang.org/t/checking-a-nillable-type-prior-to-passing-it-to-a-function-which-expects-it-to-not-be-nil/4085/3

WHAT'S EXPECTED
```
def test(x : Int32) : String?
  if x == 1
	 "wtf"
  else
  	nil
  end
end

x = test(1)

puts "typeof(x) OUTSIDE if x: #{typeof(x)}"
if x
  puts "typeof(x) INSIDE if x: #{typeof(x)}"
end

```

OUTPUT:
typeof(x) OUTSIDE if x: (String | Nil)
typeof(x) INSIDE if x: String

THE CODE NOT DOING WHAT'S EXPECTED
```
struct AbsoluteStatePathError
    getter msg
    getter constraints
    
    def initialize(@msg : String, @constraints : String) end
end

struct InvalidCharacterError
    getter constraints

    def initialize(@cosntraints : String) end
end

struct GuardID
    @id : String
    getter id

    def initialize(id : String)
        if /^[a-z0-9_.]+$/.match(id) === nil
            raise "ERROR: Invalid character used for id: #{id} in GuardID.new/1; must be (a-z | 0-9 | _) only."
        end
    
    	@id = "##{id}"
  	end
end

alias Guards = Array(GuardID)


struct ActionID
    @id : String
    getter id

    def initialize(id : String)
        if /^[a-z0-9_.]+$/.match(id) === nil
            raise "ERROR: Invalid character used for id: #{id} in ActionID.new/1; must be (a-z | 0-9 | _) only."
        end
    
    	@id = "##{id}"
  	end
end

alias Actions = Array(ActionID)

struct EventType
    @type : String
    getter type

    def initialize(type : String)
        if /^[A-Z0-9_.]+$/.match(type) === nil
            nil
        end
    
        @type = type
    end
end

struct RelativeStateID
    @id : String
    getter id

    def initialize(id : String)
        if id[0] == '#'
            return AbsoluteStatePathError.new("cannot start with '#'", "(a-z | 0-9 | _)")
        end

        if /^[a-z0-9_.]+$/.match(id) === nil
            return InvalidCharacterError.new("(a-z | 0-9 | _)")
        end

        @id = id
  	end
end

struct TransitionBuilder
    @event : EventType?
    @to : RelativeStateID?
    @actions : Actions?
    @guards : Guards?

    getter event
    getter to 
    getter actions
    getter guards

    def initialize(@event, @to, @actions, @guards) end

    def event(x : String)
        event_type = EventType.new(x)

        case event_type
        when EventType
            @event = event_type
            self
	    else
		    raise "ERROR: Invalid character used for event: #{x} in Transition.new/1; must be (A-Z | 0-9 | _) only."
        end
    end

    def to(x : String)
        state_id = RelativeStateID.new(x)

        case state_id
        when AbsoluteStatePathError
            raise "ERROR: id: #{x} #{state_id.msg} while constructing a Transition; must be #{state_id.constraints} only."
        when InvalidCharacterError
            raise "ERROR: Invalid character used for id: #{x} while constructing a Transition; must be #{state_id.constraints} only."
        else
            @to = state_id
            self
        end
    end

    def actions(xs : Array(String)) @actions = xs; self end
    def guards(xs : Array(String)) @guards = xs; self end

    def build()
		puts "typeof(@event) in builder() OUTSIDE OF if @event: #{typeof(@event)}"
		if @event
	  		puts "typeof(@event) in builder() INSIDE OF if @event: #{typeof(@event)}"
            Transition.new(@event, @to, @actions, @guards)
		else
        	raise "ERROR: @event cannot be nil when constructing a Transition."
        end
    end
end

struct Transition
    getter event
    getter to
    getter actions
    getter guards

    def initialize(
        @event : EventType,
        @to : RelativeStateID?,
        @actions : Actions?,
        @guards : Guards?
    ) end

    def self.builder()
        TransitionBuilder.new(nil, nil, nil, nil)
    end
end

transition = Transition.builder().event("show_flop").to("rand_to").build()

puts "transition: #{transition}"
```

OUTPUT:
error in line 121
Error: no overload matches 'Transition.new' with types (EventType | Nil), (RelativeStateID | Nil), (Array(ActionID) | Nil), (Array(GuardID) | Nil)

Overloads are:
 - Transition.new(event : EventType, to : RelativeStateID | ::Nil, actions : Actions | ::Nil, guards : Guards | ::Nil)
Couldn't find overloads for these types:
 - Transition.new(event : Nil, to : RelativeStateID, actions : Nil, guards : Nil)
 - Transition.new(event : Nil, to : RelativeStateID, actions : Nil, guards : Array(GuardID))
 - Transition.new(event : Nil, to : RelativeStateID, actions : Array(ActionID), guards : Nil)
 - Transition.new(event : Nil, to : RelativeStateID, actions : Array(ActionID), guards : Array(GuardID))
 - Transition.new(event : Nil, to : Nil, actions : Nil, guards : Nil)
 - Transition.new(event : Nil, to : Nil, actions : Nil, guards : Array(GuardID))
 - Transition.new(event : Nil, to : Nil, actions : Array(ActionID), guards : Nil)
 - Transition.new(event : Nil, to : Nil, actions : Array(ActionID), guards : Array(GuardID))


 # ANOTHER FAWKING POTENTIAL SHOWSTOPPER
 Again... taken from a larger project, will need to run this shiz in the
 Crystal playground.
 This issue stems from the fact that AbsoluteStateID may return an error....
 In my use case, I want to construct two AbsoluteStateIDs and then return both in a Tuple
 ```
 struct AbsoluteStateID
    @id : String
    getter id

    def initialize(id : String)
        if id[0] != '#'
            return AbsoluteStatePathError.new("must start with '#'", "(a-z | 0-9 | _)")
        end

        if /^[a-z0-9_.]+$/.match(id) === nil
            return InvalidCharacterError.new("(a-z | 0-9 | _)")
        end

        @id = id
  	end
end

def handle_potential_error(val, x)
        case val
        when State::AbsoluteStatePathError
            raise "ERROR: id: #{x} #{val.msg} while constructing a Parallel state; must be #{val.constraints} only."
        when State::InvalidCharacterError
            raise "ERROR: Invalid character used for id: #{x} while constructing an AbsoluteStateId in create_from_and_to_absolute_state_ids/2; must be #{val.constraints} only."
        end
    end

     def create_from_and_to_absolute_state_ids(from_str : String, to_str : String)
        from = State::AbsoluteStateID.new(from_str)
        to = State::AbsoluteStateID.new(to_str)

        handle_potential_error(to, to_str)
        handle_potential_error(from, from_str)
        # case to
        # when State::AbsoluteStatePathError
        #     raise "ERROR: id: #{to_str} #{to.msg} while constructing a Parallel state; must be #{to.constraints} only."
        # when State::InvalidCharacterError
        #     raise "ERROR: Invalid character used for id: #{to_str} while constructing an AbsoluteStateId in create_from_and_to_absolute_state_ids/2; must be #{to.constraints} only."
        # end

        # case from
        # when State::AbsoluteStatePathError
        #     raise "ERROR: id: #{from_str} #{from.msg} while constructing a Parallel state; must be #{from.constraints} only."
        # when State::InvalidCharacterError
        #     raise "ERROR: Invalid character used for id: #{from_str} while constructing an AbsoluteStateId in create_from_and_to_absolute_state_ids/2; must be #{from.constraints} only."
        # end

        puts "typeof(from) AFTER handle_potential_error: #{typeof(from)}"
        if from && to
            {from.as(State::AbsoluteStateID), to.as(State::AbsoluteStateID)}
        end
    end
 ```

 ^^ When I test this... the code will run without error IFF
 the return of the Tuple containing the (Supposedly) State::AbsoluteStateID
 at that point in time.

 If you uncomment the Tuple return... then you get a hell of a stack trace:
 <!-- typeof(from) AFTER handle_potential_error: State::AbsoluteStateID
Invalid memory access (signal 11) at address 0xc
[0x10ac62b7b] *Exception::CallStack::print_backtrace:Nil +107
[0x10ac49d80] ~procProc(Int32, Pointer(LibC::SiginfoT), Pointer(Void), Nil)@/usr/local/Cellar/crystal/1.2.0/src/signal.cr:127 +304
[0x7fff20454d7d] _sigtramp +29
[0x10ac8724a] *Pointer(UInt8)@Pointer(T)#[]<Int32>:UInt8 +10
[0x10ac85a9e] *Char::Reader#byte_at<Int32>:UInt32 +30
[0x10ac84f24] *Char::Reader#decode_current_char:Char +36
[0x10ac84ef1] *Char::Reader#initialize<String, Int32>:Char +33
[0x10ac84ec7] *Char::Reader#initialize<String>:Char +39
[0x10ac84e46] *Char::Reader::new<String>:Char::Reader +102
[0x10ac791d4] *String#inspect<String::Builder>:Nil +84
[0x10ad4af5a] *State::AbsoluteStateID@Struct#inspect<String::Builder>:Nil +90
[0x10ad4b413] *Tuple(State::AbsoluteStateID, State::AbsoluteStateID)@Tuple(*T)#to_s<String::Builder>:Nil +131
[0x10ad4b372] *Tuple(State::AbsoluteStateID, State::AbsoluteStateID)@Object#to_s:String +66
[0x10ad4b329] *Tuple(State::AbsoluteStateID, State::AbsoluteStateID)@Tuple(*T)#inspect:String +9
[0x10ad4b0f9] *Spec::EqualExpectation(String)@Spec::EqualExpectation(T)#failure_message<Tuple(State::AbsoluteStateID, State::AbsoluteStateID)>:String +73
[0x10ad4b2f7] *Tuple(State::AbsoluteStateID, State::AbsoluteStateID)@Spec::ObjectExtensions#should<Spec::EqualExpectation(String), String, Int32>:Nil +87
[0x10ac4ccca] ~procProc(Nil)@spec/procedures/generate_state_map_spec.cr:56 +122
[0x10ad45da0] *Spec::Example#internal_run<Time::Span, Proc(Nil)>:(Array(Spec::Result) | Nil) +224
[0x10ad45c95] *Spec::Example#run:Nil +1029
[0x10ad44f5d] *Spec::ExampleGroup@Spec::Context#internal_run:Nil +125
[0x10ad44e0b] *Spec::ExampleGroup#run:Nil +363
[0x10ad1cb6b] *Spec::RootContext@Spec::Context#internal_run:Nil +171
[0x10ad1cab9] *Spec::RootContext#run:Nil +9
[0x10ac4c714] ~procProc(Int32, (Exception | Nil), Nil)@/usr/local/Cellar/crystal/1.2.0/src/spec/dsl.cr:197 +52
[0x10aceab31] *Crystal::AtExitHandlers::run<Int32, (Exception+ | Nil)>:Int32 +145
[0x10ad4c5ab] *Crystal::main<Int32, Pointer(Pointer(UInt8))>:Int32 +107
[0x10ac43449] main +9 -->

^^ This from within the testing context of my project, still going to think about potential workarounds for this, but seems like another worthy Crystal forum post.

Also tried this variation...
```
def create_from_and_to_absolute_state_ids(from_str : String, to_str : String)
        from = State::AbsoluteStateID.new(from_str)
        to = State::AbsoluteStateID.new(to_str)

        # handle_potential_error(to, to_str)
        # handle_potential_error(from, from_str)

        case to
        when State::AbsoluteStatePathError
            raise "ERROR: id: #{to_str} #{to.msg} while constructing a Parallel state; must be #{to.constraints} only."
        when State::InvalidCharacterError
            raise "ERROR: Invalid character used for id: #{to_str} while constructing an AbsoluteStateId in create_from_and_to_absolute_state_ids/2; must be #{to.constraints} only."
        else
            case from
            when State::AbsoluteStatePathError
                raise "ERROR: id: #{from_str} #{from.msg} while constructing a Parallel state; must be #{from.constraints} only."
            when State::InvalidCharacterError
                raise "ERROR: Invalid character used for id: #{from_str} while constructing an AbsoluteStateId in create_from_and_to_absolute_state_ids/2; must be #{from.constraints} only."
            else
                puts "typeof(from) AFTER handle_potential_error: #{typeof(from)}"
                {from.as(State::AbsoluteStateID), to.as(State::AbsoluteStateID)}
            end
        end
    end
```

^^ Got the same stack trace error.

# Trying to create a safe pop function, and have the least cumbersome
# end user API:
The crystal REPL playground link is most helpful... I wonder if they ever
go through and delete them periodically?
```
def pop(xs)
        x = xs[0]
        end_idx = xs.size - 1
        xs = xs[1..end_idx]
        {x, xs}
    end

def pop_fixed(xs)
  if xs.size === 0
    nil
  elsif xs.size === 1
    x = xs[0]
    # I'm a bit surprised this worked
    # {x, [] of typeof(x)}
	{x, nil}
  else
    x = xs[0]
    end_idx = xs.size - 1
    xs = xs[1..end_idx]
    {x, xs}
  end
end

# puts pop_fixed([] of String)

xs = pop_fixed(["one_el", "second"] of String)

# if xs
# 	x = xs[0]
#  	y = xs[1]
# end

# This works... and handles all cases.
# It just seems cumbersome that the user would have to write this in every location
# where pop is used.
case xs
when Tuple(String, Array(String))
	if xs[1].size === 0
		puts "first element: #{xs[0]}"
	else
		puts "first element: #{xs[0]}, rest: #{xs[1]}"
	end
else
	puts "got nil"
end

# ^^ Second end user API idea... which is a bit more functional (allowing the user to pass in a multiple dispatch function
# to handle all the cases)
# Requires creating a new type in order to avoid having to do an if/else check for whether the second element of the tuple is
# an array of size 0 or not.
# Actually, doesn't require a new type... just return {x, nil} when there's no remaining array elements, then the case statement
# can be rewritten like so:
case xs
when Tuple(String, Nil)
	puts "first element: #{xs[0]}"
when Tuple(String, Array(String))
	puts "first element: #{xs[0]}, rest: #{xs[1]}"
else
	puts "No more elements remaining..."
end

# Or by writing multiple dispatch functions:
def handle_result(x : Tuple(String, Nil))
	puts "first element: #{xs[0]}"
end

def handle_result(x : Tuple(String, Array(String)))
	puts "first element: #{xs[0]}, rest: #{xs[1]}"
end

def handle_result(x : Nil)
	puts "No more elements remaining..."
end

# handle_result(pop_fixed([] of String))
# ^^ ACTUALLY
# This doesn't work... I remember this issue with Tuples and declaring multiple case statements or dispatches on it
# error in line 75
# Error: no overload matches 'handle_result' with type (Tuple(String, Array(String) | Nil) | Nil)

# BASICALLY, You can't write these two function signatures to distinguish between the second element of the tuple...
# def handle_result(x : Tuple(String, Nil))
# def handle_result(x : Tuple(String, Array(String)))

# You HAVE to write it like so...
# Which still necesitates the if else check just as it was in the first case statement.
def handle_result_fixed(xs : Tuple(String, Array(String) | Nil))
	if xs[1].nil?
		puts "first element: #{xs[0]}"
	else
		puts "first element: #{xs[0]}, rest: #{xs[1]}"
	end
end

def handle_result_fixed(x : Nil)
	puts "No more elements remaining..."
end

handle_result_fixed(pop_fixed(["first_element"] of String))



# puts "x: #{x}, y: #{y}"

# x = "dsad"
# puts typeof(x)
# puts ([] of typeof(x))
```

# SUBTLE TYPE DIFFERENCE WHICH CAUSED AN ERROR (this seems blog post worthy... maybe)
```
# alias Strings = Array(String | Array(String))

# struct Rand
# 	@xs : Strings
  
#     def initialize(@xs) end
  
#  	 def self.builder()
#     	RandBuilder.new(nil)
#  	end
# end

# struct RandBuilder
#   @xs : Strings?
  
#   def initialize(@xs) end
  
#  def test(ys : Strings)
#  	puts "ys: #{ys}"
#    @xs = ys
#    self
#  end
  
#  def build()
#    if x = @xs
#	   Rand.new(x)
#   end
#  end
# end

#Rand.builder().test(["wtf", ["nested_wtf"]]).build()

# Works with the Strings type... (does using a non primitive type change things?)

struct Transition
  def initialize(@id : String) end
end

# WTF: Subtle type declaration error.... (had me stuck for at least 20 minutes)
# It's not an issue with Crystal, just the way I wrote the type declaration

# alias Transitions = Array(Transition | Array(Transition))
# @transitions = [Transition.new("wtf"), [Transition.new("nested_wtf")]
# ^^ THIS WORKS FINE...

# alias Transitions = Array(Transition | Array(Transition))
# @transitions = [Transition.new("wtf")] # <- will cause an error

# SOLUTION:
# alias Transitions = Array(Transition | Array(Transition)) | Array(Transition)
# ^^ ANd now both will work:
# @transitions = [Transition.new("wtf")]
# OR
# @transitions = [Transition.new("wtf"), [Transition.new("nested_wtf")]

struct Rand
	@transitions : Transitions?
	getter transitions
  
    def initialize(@transitions) end
  
  	def self.builder()
    	RandBuilder.new(nil)
  	end
end

struct RandBuilder
  @transitions : Transitions?
  
  def initialize(@transitions) end
  
  def transitions(ys : Transitions)
    @transitions = ys
    self
  end
  
  def build()
    if x = @transitions
	   Rand.new(x)
    end
  end
end

Rand.builder().transitions([Transition.new("wtf")]).build()
```

# Array Mutation
```
xs = [] of String
 
def test(xs)
    xs.push("wtf")
end

test(xs)

puts xs
OUTPUTS => ["wtf"]
```
# designing_with_types_f_sharp_to_crystal_translation
