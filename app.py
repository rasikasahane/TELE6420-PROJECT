from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from config import Config
import os

# Create Flask app instance
app = Flask(__name__)
app.config.from_object(Config)

# Initialize the database
db = SQLAlchemy(app)

# Define the Student model
class Student(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    gpa = db.Column(db.Numeric(3, 2), nullable=False)

# Function to initialize the database
def initialize_database():
    with app.app_context():
        # Create tables if they don't exist
        db.create_all()
        
        # Check if the database is empty before populating
        if not Student.query.first():
            students = [
                Student(name="Rasika", gpa=3.8),
                Student(name="Issa", gpa=3.7),
                Student(name="Rohit", gpa=3.9),
            ]
            db.session.add_all(students)
            db.session.commit()
            print("Database initialized with sample data.")

# Call the initialization function
initialize_database()

# Define an API endpoint to fetch all students
@app.route('/students', methods=['GET'])
def get_students():
    students = Student.query.all()

    # Prepare the output as plain text with proper alignment
    output = "Students:\n"
    output += "{:<10} {:>5}\n".format("Name", "GPA")  # Header with proper alignment
    for student in students:
        output += "{:<10} {:>5.2f}\n".format(student.name, student.gpa)  # Proper alignment for name and GPA

    # Return the output as preformatted text so the alignment is preserved in the browser
    return f"<pre>{output}</pre>"

if __name__ == '__main__':
    
    port = int(os.getenv('FLASK_RUN_PORT', 8080))
    app.run(debug=True, host='0.0.0.0', port=port)
