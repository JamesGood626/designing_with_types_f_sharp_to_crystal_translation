# https://fsharpforfunandprofit.com/posts/designing-with-types-discovering-the-domain/

# Making the business rule more complicated:

# Now let's say that the business decides that phone numbers need to be supported as well.
# The new business rule is: "A contact must have at least one of the following: an email, a postal address, a home phone, or a work phone."

# How can we represent this now?
# There are now 15 possible combinations of these four contact methods.
# Creating a union type for the above would be cumbersome; is there a better way?

# https://fsharpforfunandprofit.com/posts/designing-with-types-discovering-the-domain/#forcing-breaking-changes-when-requirements-change

# Say we have this type:
# type ContactInformation =
#     {
#     EmailAddresses : EmailContactInfo list;
#     PostalAddresses : PostalContactInfo list
#     }

# And, also let's say that you have created a printReport function that loops through the info and prints it out in a report:
# // mock code
# let printEmail emailAddress =
#     printfn "Email Address is %s" emailAddress

# // mock code
# let printPostalAddress postalAddress =
#     printfn "Postal Address is %s" postalAddress

# let printReport contactInfo =
#     let {
#         EmailAddresses = emailAddresses;
#         PostalAddresses = postalAddresses;
#         } = contactInfo
#     for email in emailAddresses do
#          printEmail email
#     for postalAddress in postalAddresses do
#          printPostalAddress postalAddress

# Now if the new business rule comes into effect, the updated structure will now look something like this:
# type PhoneContactInfo = string // dummy for now

# type ContactInformation =
#     {
#     EmailAddresses : EmailContactInfo list;
#     PostalAddresses : PostalContactInfo list;
#     HomePhones : PhoneContactInfo list;
#     WorkPhones : PhoneContactInfo list;
#     }

# ^^ If you make this change, you also want to make sure that all the functions that process the contact information are
# updated to handle the new phone cases as well.
# !!!
# Certainly, you will be forced to fix any pattern matches that break.
# But in many cases, you would NOT be foreced to handle the new cases.
# (printReport in this case wouldn't be forced to change the function to handle the phones; the new fields in the record
# have not caused the code to break at all).
# !!!

# So we have the challenge: can we design types such that these situations cannot easily happen?

# https://fsharpforfunandprofit.com/posts/designing-with-types-discovering-the-domain/#deeper-insight-into-the-domain
# If you think about this example a bit more deeply, you will realize that we have missed the forest for the trees.

# Our initial concept was: "to contact a customer, there will be a list of possible emails, and a list of possible addresses, etc."

# But really, this is all wrong.
# A much better concept is: "To contact a customer, wthere will be a list of contact methods.
# Each contact method could be an email OR a postal address OR a phone number".

# This is a key insight into how the domain should be modelled.
# It creates a whole new type, a "ContactMethod", which resolves our problems in one stroke.

# type ContactMethod =
#     | Email of EmailContactInfo
#     | PostalAddress of PostalContactInfo
#     | HomePhone of PhoneContactInfo
#     | WorkPhone of PhoneContactInfo

# type ContactInformation =
#     {
#     ContactMethods  : ContactMethod list;
#     }

abstract struct PhoneContactInfo
    def initialize(@phone : String) end
end

struct HomePhone < PhoneContactInfo
end

struct WorkPhone < PhoneContactInfo
end

alias ContactMethod = EmailContactInfo | PostalContactInfo | HomePhone | WorkPhone

struct ContactInformation
  getter contact_methods

  def initialize(@contact_methods : Array(ContactMethod)) end
end

hp = HomePhone.new("602-675-2313")
wp = WorkPhone.new("602-675-8900")
puts hp
# OUTPUT: HomePhone(@phone="602-675-2313")

# ANd now the reporting code must now be changed to handle the new type as well:
# // mock code
# let printContactMethod cm =
#     match cm with
#     | Email emailAddress ->
#         printfn "Email Address is %s" emailAddress
#     | PostalAddress postalAddress ->
#          printfn "Postal Address is %s" postalAddress
#     | HomePhone phoneNumber ->
#         printfn "Home Phone is %s" phoneNumber
#     | WorkPhone phoneNumber ->
#         printfn "Work Phone is %s" phoneNumber

# let printReport contactInfo =
#     let {
#         ContactMethods=methods;
#         } = contactInfo
#     methods
#     |> List.iter printContactMethod

def print_contact_method(email : EmailContactInfo)
    puts "Email Address is #{email}"
end

def print_contact_method(postal_address : PostalContactInfo)
    puts "Postal Address is #{postal_address}"
end

def print_contact_method(home_phone : HomePhone)
    puts "Home Phone is #{home_phone}"
end

def print_contact_method(work_phone : WorkPhone)
    puts "Work Phone is #{work_phonee}"
end

def print_report(contact_info : ContactInformation)
    # https://crystal-lang.org/api/1.1.1/Iterator.html#each(&:T-%3E_):Nil-instance-method
    contact_info.contact_methods.each { |contact_method : ContactMethod| { print_contact_method(contact_method) } }
end

# Try to run it like this:
puts print_report(ContactInformation.new([hp]))

# And you'll get the following error:
# Error: instance variable '@contact_methods' of ContactInformation must be Array(EmailContactInfo | PhoneContactInfo | PostalContactInfo), not Array(HomePhone)

# This can be fixed by calling it like this instead (using a type cast):
puts print_report(ContactInformation.new([hp, wp] of ContactMethod))

# ^^ These changes have a number of benefits:
# 1. From a modeling point of view, the new types represent the domain much better, and are more adaptable to changing requirements.
# 2. And from a development point of view, changing the type to be a union means that any new cases that we add (or remove) will break the code
#    in a very obvious way, and it will be much harder to accidentally forget to handle all the cases.

# https://fsharpforfunandprofit.com/posts/designing-with-types-discovering-the-domain/#back-to-the-business-rule-with-15-possible-combinations
# With new insight from the reporting problem, this affects our understanding of the business rule.

# With the "ContactMethod" concept in our heads, we can rephase the requirement as: "A customer must have at least one contact method.
# A contact method could be an email OR a postal address OR a phone number"

# So let's redesign the Contact type to have a list of contact methods:
# type Contact =
#     {
#     Name: PersonalName;
#     ContactMethods: ContactMethod list;
#     }

# From this in Crystal:
struct Contact
    getter name
    getter contact_info

    def initialize(@name : String, @contact_info : ContactInfo) end
end

# To this in Crystal:
struct Contact
    getter name
    getter contact_methods

    def initialize(@name : String, @contact_methods : Array(ContactMethod)) end
end

# But this is still not quite right. The list could be empty.
# How can we enforce the rule that there must be AT LEAST ONE contact method?

# The simplest way is to create a new field that is required, like this:
# type Contact =
#     {
#     Name: PersonalName;
#     PrimaryContactMethod: ContactMethod;
#     SecondaryContactMethods: ContactMethod list;
#     }

struct Contact
    getter name
    getter primary_contact_method
    getter secondary_contact_methods

    def initialize(
        @name : String,
        @primary_contact_method : ContactMethod,
        @secondary_contact_methods : Array(ContactMethod)
    ) end
end

# ^^ In this design, the primary_contact_method is required, and the second_contact_methods are optional, which
#    is exactly what the business rule requires!

# ANd this refactoring too, has given us some insight.
# It may be that the concepts of "primary" and "secondary" contact methods might, in turn, clarify code in other areas,
# creating a cascading change of insight and refactoring.

# In the Domain Driven Design book, Eric Evans devotes a whole section and two chapters in particular
# (chapters 8 and 9) to discussing the importance of refactoring towards deeper insight.
# https://www.dddcommunity.org/wp-content/uploads/files/books/evans_pt03.pdf

