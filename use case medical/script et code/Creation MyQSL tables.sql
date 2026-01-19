-- Création de la table healthcare avec une clé primaire
CREATE TABLE healthcare (
    patient_id        INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name              VARCHAR(255),
    age               INT,
    gender            VARCHAR(6),
    blood_type        VARCHAR(3),
    medical_condition VARCHAR(12),
    date_of_admission DATE,
    doctor            VARCHAR(255),
    hospital          VARCHAR(255),
    insurance_provider VARCHAR(16),
    billing_amount    INT,
    room_number       INT,
    admission_type    VARCHAR(9),
    discharge_date    DATE,
    medication        VARCHAR(11),
    test_results      VARCHAR(12)
    
);


 