-- Create Tables
CREATE TABLE IF NOT EXISTS country_elec_ce (
    country VARCHAR(50) PRIMARY KEY,
    carbon_intensity_g_kwh INT
);

CREATE TABLE IF NOT EXISTS raw_materials (
    material_id INT AUTO_INCREMENT PRIMARY KEY,
    material_name VARCHAR(100) NOT NULL,
    unit INT,
    emission INT
);

CREATE TABLE IF NOT EXISTS manufacturing_process (
    process_id INT AUTO_INCREMENT PRIMARY KEY,
    process_name VARCHAR(100) NOT NULL,
    unit INT,
    emission INT
);

CREATE TABLE IF NOT EXISTS transport_modes (
    transport_id INT PRIMARY KEY,
    vehicle_type VARCHAR(100) NOT NULL,
    transport_category VARCHAR(50) NOT NULL,
    ef_fixed DECIMAL(10, 4) NOT NULL,
    ef_marginal DECIMAL(10, 6) NOT NULL
);

-- Insert Raw Materials
INSERT INTO raw_materials (material_name, emission) VALUES
('Primary Aluminum', 14.0), 
('Nickel', 15.5), 
('Lithium from Hard Rock', 13.5), 
('Cobalt', 10.0), 
('Magnesium', 18.5), 
('Titanium', 37.5), 
('Copper', 3.75), 
('Virgin Plastics', 2.75), 
('Primary Steel', 2.05), 
('Silicon for Solar Panels', 11.0), 
('Synthetic Fiber/Carbon Fiber', 27.5), 
('Conventional Cotton Fiber', 3.0), 
('Paper from Virgin Pulp', 1.05), 
('Glass', 0.9), 
('Cement Clinker', 0.85), 
('Crude Oil Extraction', 0.6), 
('Ammonia', 2.15), 
('Sawn Wood/Timber', 0.35), 
('Coal Extraction', 0.22), 
('Gypsum/Plaster', 0.2), 
('Sulfur/Sulfuric Acid', 0.2), 
('Gold', 25000.0), 
('Platinum/Palladium', 14000.0), 
('Rare Earth Oxides', 40.0), 
('Lithium from Brine', 4.0), 
('Recycled Aluminum', 0.8), 
('Recycled Steel', 0.5);

-- Insert Manufacturing Processes
INSERT INTO manufacturing_process (process_name, emission) VALUES
('Steam Cracking for Petrochemicals', 1.8), 
('Blast Furnace Steelmaking', 2.2), 
('Electric Arc Furnace Steelmaking', 0.5), 
('Hall-Héroult Aluminum Smelting', 11.5), 
('Haber-Bosch Ammonia Synthesis', 2.1), 
('Contact Process for Sulfuric Acid', 0.15), 
('Solvay Process for Soda Ash', 0.6), 
('Clinker Calcination', 0.55), 
('Float Glass Manufacturing', 0.95), 
('Hydrocolloids/Solvent Extraction', 4.5), 
('Fluid Catalytic Cracking for Gasoline', 0.25), 
('Mechanical Rock Crushing and Milling', 0.15), 
('High-Pressure Acid Leaching for Nickel', 11.0), 
('Kroll Process for Titanium', 32.0), 
('Pidgeon Process for Magnesium', 19.0), 
('Siemens Process for Polysilicon', 9.5), 
('Kraft Pulping for Paper', 0.65), 
('Polymerization for HDPE/LLDPE', 0.8);

-- Insert Transport Modes
INSERT INTO transport_modes VALUES 
(1, 'Van / Urban Delivery (<3.5t)', 'Road', 0.2600, 0.0800),
(2, 'Medium Rigid Truck (19t)', 'Road', 0.6200, 0.0220),
(3, 'Heavy Rigid Truck (26t)', 'Road', 0.7400, 0.0180),
(4, 'Semi-trailer (40-44t)', 'Road', 0.7700, 0.0120),
(5, 'Electric Freight Train (Europe)', 'Rail', 0.1500, 0.0040),
(6, 'Transoceanic Cargo Ship', 'Maritime', 5.0000, 0.0120),
(7, 'Long-haul Cargo Plane', 'Air', 22.0000, 0.5800);

-- Insert Country Electricity Carbon Intensity
INSERT INTO country_elec_ce (country, carbon_intensity_g_kwh) VALUES
('Sweden', 10),
('France', 20),
('Lithuania', 25),
('Luxembourg', 40),
('Austria', 55),
('Finland', 55),
('Denmark', 65),
('Portugal', 75),
('Croatia', 120),
('Slovakia', 120),
('Spain', 130),
('Belgium', 135),
('Great Britain', 175),
('Slovenia', 180),
('Latvia', 180),
('Romania', 195),
('Italy', 230),
('Hungary', 230),
('Netherlands', 240),
('Ireland', 255),
('Greece', 265),
('United States', 330),
('Germany', 330),
('Malta', 360),
('Russia', 380),
('Czechia', 380),
('Bulgaria', 390),
('Estonia', 420),
('Algeria', 500),
('China', 530),
('Morocco', 550),
('Cyprus', 550),
('Poland', 610),
('India', 695),
('Brazil', 45),
('Canada', 65),
('Philippines', 430),
('Indonesia', 590),
('Pakistan', 600),
('South Africa', 710);
