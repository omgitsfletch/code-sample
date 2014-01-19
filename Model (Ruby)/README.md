# Model : Account #

#### File Details ####

*Created* : November 2013  
*Original Location* : ```/app/models/account.rb  ```

#### File Description ####

This model class for user accounts is used on a small site I'm creating in my free time. It has a number of features: some slightly complex input validations; integration with bcrypt for more secure password hashing; salting to avoid attacks/vulnerabilities such as pre-computed/rainbow tables, should the database was ever compromised. Finally, an account lockout function to prevent brute forcing access to an account. I plan to flesh this model out further over time as the requirements and features of the site grow.
