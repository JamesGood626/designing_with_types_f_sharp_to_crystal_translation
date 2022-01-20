# https://fsharpforfunandprofit.com/posts/designing-with-types-making-illegal-states-unrepresentable/

# The contact type from the previous refactoring:
# type Contact =
#     {
#     Name: Name;
#     EmailContactInfo: EmailContactInfo;
#     PostalContactInfo: PostalContactInfo;
#     }

# Now let's say that we have the following simple business rule:
# "A contact must have an email or a postal address".

# If we make the fields optional, then we go too far in the wrong direction;
# it would be possible for a contact to have neither type of address at all.

# type Contact =
#     {
#     Name: PersonalName;
#     EmailContactInfo: EmailContactInfo option;
#     PostalContactInfo: PostalContactInfo option;
#     }

################################################
# Making illegal states unrepresentable
################################################
# If we think about the business rule carefully, we realize that there are three possibilities:
# - A contact only has an email address
# - A contact only has a postal address
# - A contact has both a email address and a postal address

# The solution becomes obvious -- use a union type with a case for each possibility:

# type ContactInfo =
#    | EmailOnly of EmailContactInfo
#    | PostOnly of PostalContactInfo
#    | EmailAndPost of EmailContactInfo * PostalContactInfo

# ^^ This design meets the requirements perfectly.
# All three cases are explicitly represented, and the fourth possible case (with no email or postal address at all) is not allowed.

# ^^ Have to create an extra struct to represent EmailContactInfo * PostalContactInfo in Crystal
# Ahhh... actually, the * is shorthand for a Tuple in F#,
# so you're alias type could be:
alias ContactInfo = EmailContactInfo | PostalContactInfo | Tuple(EmailContactInfo, PostalContactInfo)

# type Contact =
#    {
#    Name: Name;
#    ContactInfo: ContactInfo;
#    }

struct EmailContactInfo
  def initialize(@email : String) end
end

struct PostalContactInfo
    def initialize(@postal : String) end
end

struct EmailAndPostal
  def initialize(@email : EmailContactInfo, @postal : PostalContactInfo) end
end

# The Union Type encodes a business rule
alias ContactInfo = EmailContactInfo | PostalContactInfo | EmailAndPostal

struct Contact
  def initialize(@name : String, @contact_info : ContactInfo) end
end

###############################
# Constructing a ContactInfo
# https://crystal-lang.org/reference/syntax_and_semantics/case.html
###############################
# let contactFromEmail name emailStr =
#     let emailOpt = EmailAddress.create emailStr
#     // handle cases when email is valid or invalid
#     match emailOpt with
#     | Some email ->
#         let emailContactInfo =
#             {EmailAddress=email; IsEmailVerified=false}
#         let contactInfo = EmailOnly emailContactInfo
#         Some {Name=name; ContactInfo=contactInfo}
#     | None -> None

# let name = {FirstName = "A"; MiddleInitial=None; LastName="Smith"}
# let contactOpt = contactFromEmail name "abc@example.com"

# vv The bit of Crystal code that does the above:
def validate_email(email : String) : String?
  email.includes?("@") ? email : nil
end

def contact_from_email(name : String, email : String) : Contact?
  email_opt = validate_email(email)
  
  case email_opt
  when String
  	contact_info = EmailContactInfo.new(email)
  	Contact.new(name, contact_info)
  else
	  nil
  end
end

## 
# The entirety of the code so far:
##
struct EmailContactInfo
  def initialize(@email : String) end
end

struct PostalContactInfo
    def initialize(@postal : String) end
end

alias ContactInfo = EmailContactInfo | PostalContactInfo | Tuple(EmailContactInfo, PostalContactInfo)

struct Contact
  def initialize(@name : String, @contact_info : ContactInfo) end
end

def validate_email(email : String) : String?
  email.includes?("@") ? email : nil
end

def contact_from_email(name : String, email : String) : Contact?
  email_opt = validate_email(email)
  
  case email_opt
  when String
  	contact_info = EmailContactInfo.new(email)
  	Contact.new(name, contact_info)
  else
	  nil
  end
end

success = contact_from_email("John", "smith@gmail.com")
failure = contact_from_email("Tarzan", "dasdadasda")

puts "success: #{success}"
puts "failure: #{failure}"

# OUTPUTS:
# success: Contact(@name="John", @contact_info=EmailContactInfo(@email="smith@gmail.com"))
# failure: 
## 
# END The entirety of the code so far:
######################################################################################

############################
# https://fsharpforfunandprofit.com/posts/designing-with-types-making-illegal-states-unrepresentable/#updating-a-contactinfo
############################

# If we need to add a postal address to an existing ContactInfo, we have no choice but to handle all three possible cases:
# - If a contact previously only had an email address, it now has both an email address and a postal address,
#   so return a contact using the EmailAndPost case.
# - If a contact previously only had a email address and a postal address, return a contact using the PostOnly case, replacing the existing address.
# - If a contact previously had both an email address and a postal address, return a contact with using the EmailAndPost case, replacing
#   the existing address.

# let updatePostalAddress contact newPostalAddress =
#     let {Name=name; ContactInfo=contactInfo} = contact
#     let newContactInfo =
#         match contactInfo with
#         | EmailOnly email ->
#             EmailAndPost (email,newPostalAddress)
#         | PostOnly _ -> // ignore existing address
#             PostOnly newPostalAddress
#         | EmailAndPost (email,_) -> // ignore existing address
#             EmailAndPost (email,newPostalAddress)
#     // make a new contact
#     {Name=name; ContactInfo=newContactInfo}

# vv And the above code in use:
# let contact = contactOpt.Value   // see warning about option.Value below
# let newPostalAddress =
#     let state = StateCode.create "CA"
#     let zip = ZipCode.create "97210"
#     {
#         Address =
#             {
#             Address1= "123 Main";
#             Address2="";
#             City="Beverly Hills";
#             State=state.Value; // see warning about option.Value below
#             Zip=zip.Value;     // see warning about option.Value below
#             };
#         IsAddressValid=false
#     }
# let newContact = updatePostalAddress contact newPostalAddress

###################################
# Crystal code for the above (I'm omitting the various fields of an actual address and just using a simple String instead)
###################################

struct EmailContactInfo
  def initialize(@email : String) end
end

struct PostalContactInfo
    def initialize(@postal : String) end
end

alias ContactInfo = EmailContactInfo | PostalContactInfo | Tuple(EmailContactInfo, PostalContactInfo)

struct Contact
  getter name
  getter contact_info
  
  def initialize(@name : String, @contact_info : ContactInfo) end
end

def validate_email(email : String) : String?
  email.includes?("@") ? email : nil
end

def contact_from_email(name : String, email : String) : Contact?
  email_opt = validate_email(email)
  
  case email_opt
  when String
  	contact_info = EmailContactInfo.new(email)
  	Contact.new(name, contact_info)
  else
	nil
  end
end

success = contact_from_email("John", "smith@gmail.com")
failure = contact_from_email("Tarzan", "dasdadasda")

puts "success: #{success}"
puts "failure: #{failure}"

# This is an annoyance.... just because a function returns a nilable type... then any downstream functions
# will need to have a function head signature with that type as Nilable.
# error in line 58
# Error: no overload matches 'update_postal_address' with types (Contact | Nil), PostalContactInfo

# Overloads are:
#  - update_postal_address(contact : Contact, new_postal_address : PostalContactInfo)
# Couldn't find overloads for these types:
#  - update_postal_address(contact : Nil, new_postal_address : PostalContactInfo)
# def update_postal_address(contact : Nil, new_postal_address : PostalContactInfo)
# 	raise "update_postal_address/2 was provided a contact of type Nil, required type Contact instead."
# end

def update_postal_address(contact : Contact, new_postal_address : PostalContactInfo) : Contact
	name = contact.name
	ci = contact.contact_info

	new_contact_info =
      case ci
      when EmailContactInfo
  		  {ci, new_postal_address}
      when PostalContactInfo
          new_postal_address
      when Tuple(EmailContactInfo, PostalContactInfo)
		    {ci[0], new_postal_address}
      end

    Contact.new(name, new_contact_info)
end


updated_contact = nil

if !success.nil?
  updated_contact = update_postal_address(success, PostalContactInfo.new("USA"))
end

puts "updated_contact: #{updated_contact}"


# BAHHHH.... Another Type Annoyance.
# THIS CASE IS EXHAUSTIVE, SO WHY IS Nil EVEN APPEARING IN THE UNION?!??!!
ci = EmailContactInfo.new("randemail")
new_postal_address = PostalContactInfo.new("randpostal")
 
new_contact_info =
      case ci
      when EmailContactInfo
  		  {ci, new_postal_address}
      when PostalContactInfo
        new_postal_address
      when Tuple(EmailContactInfo, PostalContactInfo)
		    {ci[0], new_postal_address}
      end
 
puts typeof(new_contact_info)

# OUTPUT:
# (PostalContactInfo | Tuple(EmailContactInfo, PostalContactInfo) | Nil)

# ^^ This output really doesn't make sense... it seems as though it's an erroneous assumption on the compiler's part.

# One way to get around this is to just use Multiple Dispatch...
ci = EmailContactInfo.new("randemail")
new_postal_address = PostalContactInfo.new("randpostal")

def create_new_contact_info(contact_info : EmailContactInfo, new_postal_address : PostalContactInfo)
  {contact_info, new_postal_address}
end

def create_new_contact_info(contact : PostalContactInfo, new_postal_address : PostalContactInfo)
  new_postal_address
end

def create_new_contact_info(contact_info : Tuple(EmailContactInfo, PostalContactInfo), new_postal_address : PostalConactInfo)
  {contact_info[0], new_postal_address}
end

new_contact_info = create_new_contact_info(ci, new_postal_address)
     
puts typeof(new_contact_info)

# OUTPUT:
# Tuple(EmailContactInfo, PostalContactInfo)

#########
# The full example of updating a Contact with a PostalContactInfo
#######

# ... Omitted fields above from the creation of a Contact
success = contact_from_email("John", "smith@gmail.com")
failure = contact_from_email("Tarzan", "dasdadasda")
 
puts "success: #{success}"
puts "failure: #{failure}"
 
def create_new_contact_info(contact_info : EmailContactInfo, new_postal_address : PostalContactInfo)
  {contact_info, new_postal_address}
end
 
def create_new_contact_info(contact_info : PostalContactInfo, new_postal_address : PostalContactInfo)
  new_postal_address
end
 
def create_new_contact_info(contact_info : Tuple(EmailContactInfo, PostalContactInfo), new_postal_address : PostalContactInfo)
  {contact_info[0], new_postal_address}
end
 
def update_postal_address(contact : Contact, new_postal_address : PostalContactInfo) : Contact
	name = contact.name
	ci = contact.contact_info
 
	new_contact_info = create_new_contact_info(ci, new_postal_address)
 
    Contact.new(name, new_contact_info)
end

updated_contact = nil
if !success.nil? # checking !failure.nil? here will result in the below never running and then updated_contact will remain nil
  updated_contact = update_postal_address(success, PostalContactInfo.new("USA"))
end

puts "The updated contact: #{updated_contact}"

# A helper function to abstract away the check.
def nil_check_op(x, func)
  !x.nil? ? func.call(x) : nil
end

# https://crystal-lang.org/reference/syntax_and_semantics/proc_literal.html
updated_contact = nil_check_op(success, ->(contact_info : Contact) { update_postal_address(contact_info, PostalContactInfo.new("USA")) })

# OUTPUT:
# success: Contact(@name="John", @contact_info=EmailContactInfo(@email="smith@gmail.com"))
# failure: 
# The updated contact: Contact(@name="John", @contact_info={EmailContactInfo(@email="smith@gmail.com"), PostalContactInfo(@postal="USA")})

########
# END
########

# https://fsharpforfunandprofit.com/posts/designing-with-types-making-illegal-states-unrepresentable/#why-bother-to-make-these-complicated-types
# "First, the business logic is complicated. There is no easy way to avoid it.
# If your code is not this complicated, you are not handling all the cases properly."

# "Second, if the logic is represented by types, it is automatically self documenting.
# You can look at the union cases below and immediately see what the business rule is.
# You do not have to spend any time trying to analyze any other code."

# alias ContactInfo = EmailContactInfo | PostalContactInfo | Tuple(EmailContactInfo, PostalContactInfo)

# !!!
# "Finally, if the logic is represented by a type, any changes to the business rules will immediately create breaking changes, which is generally a good thing."
# ^^ The next part will dig deeper into this point.
# !!!




