[![General Assembly Logo](https://camo.githubusercontent.com/1a91b05b8f4d44b5bbfb83abac2b0996d8e26c92/687474703a2f2f692e696d6775722e636f6d2f6b6538555354712e706e67)](https://generalassemb.ly/education/web-development-immersive)

# Rails API Many-To-Many Clinic Code Along

1.  Fetch all with `git fetch --all`
1.  Checkout `upstream` with `git checkout upstream/training/many-to-many`
1.  Checkout and branch with `git checkout -b training/many-to-many`
1.  *WHEN YOU ARE READY TO PUSH* do so with `git push --set-upstream origin training/many-to-many`
1.  Install dependencies with `bundle install`.
1.  Add secrets to `config/secrets.yml`.
1.  Create a database with `bundle exec rake db:create`.
1.  Create a database schema with `bundle exec rake db:migrate`.
1.  Run the HTTP server with `bundle exec rails server`.

## Where We Left Off

Previously we created a single model, `Patient`.

Then we created a second model `Doctor` and linked it to `Patient`.

Now we are going to add a third model: `Appointment`. Which is going to act as
a linkbetween the `Doctor`s and `Patient`s.

This `Appointment` model will join together `Doctor` and `Patient`.  Earlier, when we
were working with a `one-to-many` relationship `patients` belonged to a `doctor`.

We know this is a two way street however: `Patients` can have many `Doctors` and
`Doctors` can have many `Paients`.  When we created a migration:

```ruby
class AddDoctorToPatients < ActiveRecord::Migration
  def change
    add_reference :patients, :doctor, index: true, foreign_key: true
  end
end
```

We added a `doctor` reference column to the `patient` table which is able to
store a reference to a patient of a particular doctor.

In order to make this a two way street we are going to need a `join table`.

## Join Tables

A `join table` is a special table which holds refrences two or more tables.

Let's see what this table might look like:

![has_many_through](https://cloud.githubusercontent.com/assets/10408784/17598817/451a3662-5fca-11e6-8ad1-613d4e56970f.png)

<!-- Image from Rails Docs -->

In the above example the `appointments` table is the `join table`. You can see
it has both a `physician_id` column and a `patient_id` column.  Both of these
columns store refrences to their respective tables.

You can also see a column called `appointment_date`. You are allowed to add
other columns on to your `join table`, but do not necessarily have to.  In this
case it makes sense, in some cases it may not, use your judgement.

## Removing a Column

But wait! We forgot an important step! Yesterday we added an `doctor_id` column
to `patient`. Let's remove that before we go any further and our API performs in
a way we don't expect.

We need to create a migration to remove that column, from the Rails Guides:

```markdown
If the migration name is of the form "AddXXXToYYY" or "RemoveXXXFromYYY" and is
followed by a list of column names and types then a migration containing the
appropriate add_column and remove_column statements will be created.
```

Knowing this we can construct a migration that removes this column for us:

```bash
rails g migration RemoveDoctorIdFromPatient doctor_id:integer
```

and this creates the following migration:

```ruby
class RemoveAuthorIdFromBooks < ActiveRecord::Migration
  def change
    remove_column :patients, :doctor_id, :integer
  end
end
```

Now let's run this migration with `rake db:migrate`.

## Making a Join Table

We're going to use the generators that Rails provides to generate a `appointment`
model along with a `appointment` migration that includes references to both
`patient` and `doctor`.

```ruby
rails g scaffold appointment doctor:references patient:references date:datetime
```

Along with creating a `appointment` model, controller, routes, and serializer,
Rails will create this migration:

```ruby
class CreateAppointments < ActiveRecord::Migration
  def change
    create_table :appointments do |t|
      t.references :doctor, index: true, foreign_key: true
      t.references :patient, index: true, foreign_key: true
      t.datetime :date

      t.timestamps null: false
    end
  end
end
```

So our `appointment` table now has the following columns: ID, doctor_id,
patient_id, Date.

Let's run our migration with `rake db:migrate`

Let's take a peek at our database and see how this table looks. Simply type:

```bash
rails db
```

If your prompt looks like this `rails-api-library-demo_development=#` type:

```bash
\d appointments
```

You will be able to see all the columns contained in the `appointment` table.

## Through: Associated Records

While we can see that in the `appointment` model some some code was added for us:

```ruby
class Appointment < ActiveRecord::Base
  belongs_to :doctor
  belongs_to :patient
end
```

But we need to go into our models (`patient`, `doctor`, and `appointment`) and
add some more code to finish creating our associations.

Let's go ahead and add that code starting with the `patient` model:

```ruby
# Patient Model
class Patient < ActiveRecord::Base
  has_many :doctors, through: :appointments
  has_many :appointments
end
```

In our author model we will do something similar:

```ruby
# Doctor Model
class Doctor < ActiveRecord::Base
  has_many :patients, through: :appointments
  has_many :appointments
end
```

Finally in our `appointment` model we're going to update it to:

```ruby
class Appointment < ActiveRecord::Base
  belongs_to :doctor, inverse_of: :appointments
  belongs_to :patient, inverse_of: :appointments
end
```

What is `inverse_of` and why do we need it?

When you create a `bi-directional` (two way) association, ActiveRecord does not
necessarily know about that relationship.

*I say necessarily because in future versions of Rails this is/may be resolved*

Without `inverse_of` you can get some strange behavior like this:

```ruby
a = Author.first
b = a.books.first
a.first_name == b.author.first_name # => true
a.first_name = 'Lauren'
a.first_name == b.author.first_name # => false
```

Rails will store `a` and `b.author` in different places in memory, not knowing to
change one when you change the other. `inverse_of` informs Rails of the
relationship, so you don't have inconsistancies in your data.

*For more info on this please read the [Rails Guides](http://guides.rubyonrails.org/association_basics.html)*

## Adding Via ActiveRecord

First, let's open our Rails console with `rails console`

And Let's create some doctors and patients

```ruby
# books
patient1 = Patient.create([{ given_name: 'Jason', surname: 'Weeks'}])
patient2 = Patient.create([{ given_name: 'Lauren', surname: 'Fazah'}])
patient3 = Patient.create([{ given_name: 'Antony', surname: 'Donovan'}])

#authors
doctor1 = Doctor.create([{ given_name: 'Dr.Good', surname: 'Face'}])
doctor2 = Doctor.create([{ given_name: 'Dr.Bad', surname: 'Hands'}])
doctor3 = Doctor.create([{ given_name: 'Dr.Giggles', surname: 'McGee'}])
```
Check `localhost:3000/patients` and `localhost:3000/doctors` to see if we have
created patients and doctors.

## Updating Serializers

Now that we can see some data it's time to update our serializers or these
relationships will not be as useful as they can.

Let's add the `doctor` attribute to our attributes list in our `patients` serializer.

Our finished serializer should look like this:

```ruby
class DoctorSerializer < ActiveModel::Serializer
  attributes :id, :given_name, :surname, :patients
end
```

Let's do the same in our `patients` serializer, it should look like this once,
we're done.

```ruby
class PatientsSerializer < ActiveModel::Serializer
  attributes :id, :surname, :given_name, :doctors
end
```

## Test Using Curl

Now, let's test this using curl. To connect `authors` and `patients` we are going
to post to the join table:

```bash
curl --include --request POST http://localhost:3000/appointments \
  --header "Content-Type: application/json" \
  --data '{
    "appointment": {
      "doctor_id": "2",
      "patient_id": "2"
    }
  }'
```

Using this curl request as your basis `Create`, `Read` and `Update` the appointments
table. *DO NOT DELETE*

## Dependent Destroy

Say we wanted to delete a patient or an doctor. If we delete one we proably want to
delete the association with the other.  Rails helps us with this with a method
called `depend destroy`.  Let's edit our `patient` and `doctor` model to inclde it
so when we delete one, reference to the other gets deleted as well.

Let's update our models to look like the following:

```ruby
# Doctor Model
class Doctor < ActiveRecord::Base
  has_many :patients, through: :appointments
  has_many :appointments, dependent: :destroy
end
```

```ruby
class Patient < ActiveRecord::Base
  has_many :doctors, through: :appointments
  has_many :appointments, dependent: :destroy
end
```

Test this out by using curl request to construct relationships then remove them.

```bash
curl --include --request DELETE http://localhost:3000/patients/2
```

## [License](LICENSE)

Source code distributed under the MIT license. Text and other assets copyright
General Assembly, Inc., all rights reserved.
