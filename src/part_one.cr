# https://fsharpforfunandprofit.com/posts/designing-with-types-intro/
# https://play.crystal-lang.org/#/r/c7fh/edit

# Anti-Pattern
struct Contact
    def initialize(
        @first_name : String,
        @middle_initial : String,
        @last_name : String,
        
        @email_address : String
        # true if ownership of email address is confirmed
        @is_email_verified : bool,
        
        @address_one : String,
        @address_two : String,
        @city : String,
        @state : String,
        @zip : String,
        # true if validated against address service
        @is_address_valid : bool
      ) end
  end
  
  # Guideline: Use records or tuples to group together data that are required to be consistent (that is “atomic”)
  # but don’t needlessly group together data that is not related.
  
  # In this case, it is fairly obvious that the three name values are a set, the address values are a set, and the email is also a set.
  
  # We have also some extra flags here, such as IsAddressValid and IsEmailVerified. Should these be part of the related set or not?
  # Certainly yes for now, because the flags are dependent on the related values.
  # For example, if the EmailAddress changes, then IsEmailVerified probably needs to be reset to false at the same time.
  
  # Better Pattern
  struct PostalAddress
    def initialize(
        @address_one : String,
        @address_two : String,
        @city : String,
        @state : String,
        @zip : String
      ) end
  end
  
  struct PostalContactInfo
    def initialize(
        @address : PostalAddress,
        @is_address_valid : bool
      ) end
  end
  
  struct PersonalName
    def initialize(
        @first_name : String,
        @middle_initial : String?,
        @last_name : String
      ) end
  end
  
  struct EmailContactInfo
    def initialize(
        @email_address : String,
        @is_email_verified : Bool
      ) end
  end
  
  struct ContactImproved
    def initialize(
        @name : PersonalName,
        @email_contact_info : EmailContactInfo,
        @postal_contact_info : PostalContactInfo
         ) end
  end