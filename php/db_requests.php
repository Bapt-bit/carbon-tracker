
<?php
require_once("bdd_constants.php");
require_once("fpdf/fpdf.php");

if (APP_ENV === 'development') {
    ini_set('display_errors', 1);
    error_reporting(E_ALL);
} else {
    ini_set('display_errors', 0);
    error_reporting(E_ALL); 
}

function checkApiKey() {
    $expectedKey = getenv('API_KEY');
    $providedKey = $_SERVER['HTTP_X_API_KEY'] ?? '';

    if (empty($expectedKey) || !hash_equals($expectedKey, $providedKey)) {
        header('HTTP/1.1 401 Unauthorized');
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Unauthorized']);
        exit;
    }
}
checkApiKey();
function dbConnect()
{
    try
    {

        $db = new PDO('mysql:host='.DB_SERVER.';dbname='.DB_NAME.';charset=utf8',
            DB_USER, DB_PASSWORD);
        $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        //echo $db->query('SELECT VERSION()')->fetchColumn();

    }
    catch (PDOException $exception)
    {
        error_log('DB connection error: ' . $exception->getMessage());
        header('HTTP/1.1 503 Service Unavailable');
        echo json_encode(['error' => 'Service temporarily unavailable']);
        exit;
    }
    return $db;
}


function dbGetMaterials($db){

    $request = "
            SELECT material_name
            FROM raw_materials

        ;";

        try {

            $statement = $db->prepare($request);
            $statement->execute();
            $result = $statement->fetchALL(PDO::FETCH_ASSOC);


        }
        catch (PDOException  $exception){
            error_log('Request_error: '.$exception->getMessage());
            return false;
        }

    return $result;

}

function dbGetTransport($db){

    $request = "
            SELECT vehicle_type
            FROM transport_modes

        ;";

    try {

        $statement = $db->prepare($request);
        $statement->execute();
        $result = $statement->fetchALL(PDO::FETCH_ASSOC);


    }
    catch (PDOException  $exception){
        error_log('Request_error: '.$exception->getMessage());
        return false;
    }

    return $result;

}

function dbGetelectricity($db){
    $request = "
            SELECT country
            FROM country_elec_ce

        ;";

    try {

        $statement = $db->prepare($request);
        $statement->execute();
        $result = $statement->fetchALL(PDO::FETCH_ASSOC);


    }
    catch (PDOException  $exception){
        error_log('Request_error: '.$exception->getMessage());
        return false;
    }

    return $result;

}

function dbGetprocess ($db){

    $request = "
            SELECT  process_name
            FROM manufacturing_process

        ;";

    try {

        $statement = $db->prepare($request);
        $statement->execute();
        $result = $statement->fetchALL(PDO::FETCH_ASSOC);


    }
    catch (PDOException  $exception){
        error_log('Request_error: '.$exception->getMessage());
        return false;
    }

    return $result;

}

function dbGetMaterialInfo($db, $materialName){
    $request = "SELECT * FROM raw_materials WHERE material_name = :name;";
    try {
        $statement = $db->prepare($request);
        $statement->execute(['name' => trim($materialName)]);
        $result = $statement->fetch(PDO::FETCH_ASSOC);
    }
    catch (PDOException $exception){
        error_log('Request_error: '.$exception->getMessage());
        return false;
    }
    return $result;
}

function dbGetProcessInfo($db, $processName){
    $request = "SELECT * FROM manufacturing_process WHERE process_name = :name;";
    try {
        $statement = $db->prepare($request);
        $statement->execute(['name' => trim($processName)]);
        $result = $statement->fetch(PDO::FETCH_ASSOC);
    }
    catch (PDOException $exception){
        error_log('Request_error: '.$exception->getMessage());
        return false;
    }
    return $result;
}

function dbGetElectricityInfo($db, $countryName){
    $request = "SELECT * FROM country_elec_ce WHERE country = :name;";
    try {
        $statement = $db->prepare($request);
        $statement->execute(['name' => trim($countryName)]);
        $result = $statement->fetch(PDO::FETCH_ASSOC);
    }
    catch (PDOException $exception){
        error_log('Request_error: '.$exception->getMessage());
        return false;
    }
    return $result;
}

function dbGetTransportInfo($db, $vehicleType){
    $request = "SELECT * FROM transport_modes WHERE vehicle_type = :name;";
    try {
        $statement = $db->prepare($request);
        $statement->execute(['name' => trim($vehicleType)]);
        $result = $statement->fetch(PDO::FETCH_ASSOC);
    }
    catch (PDOException $exception){
        error_log('Request_error: '.$exception->getMessage());
        return false;
    }
    return $result;
}


function enrichSteps($db, array $steps): array
{
    $enriched = [];

    foreach ($steps as $step) {
        $data = $step;

        if (!empty($step['material'])) {
            $data['material_data'] = array_map(fn($m) => dbGetMaterialInfo($db, $m), $step['material']);
        }

        if (!empty($step['process'])) {
            $data['process_data'] = array_map(fn($p) => dbGetProcessInfo($db, $p), $step['process']);
        }

        if (!empty($step['country'])) {
            $data['country_data'] = array_map(fn($c) => dbGetElectricityInfo($db, $c), $step['country']);
        }

        foreach ($step as $key => $value) {
            if (strpos($key, 'transport') === 0 && !empty($value)) {
                $data[$key . '_data'] = array_map(fn($t) => dbGetTransportInfo($db, $t), $value);
            }
        }

        $enriched[] = $data;
    }

    return $enriched;
}

function toPdfEncoding(string $text): string
{
    return mb_convert_encoding($text, 'ISO-8859-1', 'UTF-8');
}

function generateReport(array $enrichedSteps, float $grandTotal): string
{
    $pdf = new FPDF();
    $pdf->AddPage();
    $pdf->SetFont('Arial', 'B', 16);
    $pdf->Cell(0, 10, 'Carbon Footprint Report', 0, 1, 'C');
    $pdf->Ln(5);

    $stepNumber = 1;
    foreach ($enrichedSteps as $step) {
        $pdf->SetFont('Arial', 'B', 13);
        $pdf->Cell(0, 10, 'Step ' . $stepNumber, 0, 1);
        $pdf->SetFont('Arial', '', 11);

        if (!empty($step['material'])) {
            foreach ($step['material'] as $i => $materialName) {
                $materialInfo = $step['material_data'][$i] ?? null;
                $label = ($materialName === 'processed_material')
                    ? 'Processed material (factor = 1)'
                    : toPdfEncoding($materialInfo['material_name'] ?? 'N/A');
                $pdf->Cell(0, 8, 'Material: ' . $label, 0, 1);
            }
        }
        if (!empty($step['quantity'])) {
            $pdf->Cell(0, 8, 'Quantity: ' . $step['quantity'] . ' kg', 0, 1);
        }
        if (!empty($step['process_data'])) {
            foreach ($step['process_data'] as $process) {
                $pdf->Cell(0, 8, 'Process: ' . ($process['process_name'] ?? 'N/A'), 0, 1);
            }
        }
        if (!empty($step['country_data'])) {
            foreach ($step['country_data'] as $country) {
                $pdf->Cell(0, 8, 'Electricity origin: ' . ($country['country'] ?? 'N/A'), 0, 1);
            }
        }
        foreach ($step as $key => $value) {
            if (strpos($key, 'transport') === 0 && strpos($key, '_data') !== false) {
                foreach ($value as $transport) {
                    $pdf->Cell(0, 8, 'Transport: ' . ($transport['vehicle_type'] ?? 'N/A'), 0, 1);
                }
            }
            if (strpos($key, 'distance') === 0) {
                $pdf->Cell(0, 8, 'Distance: ' . $value . ' km', 0, 1);
            }
        }

        if (!empty($step['emissions'])) {
            $pdf->Ln(2);
            $pdf->SetFont('Arial', 'I', 11);
            $e = $step['emissions'];
            $pdf->Cell(0, 8, 'Material emissions: ' . toPdfEncoding(round($e['material']), 2) . ' kg CO2e', 0, 1);
            $pdf->Cell(0, 8, 'Process emissions: ' . toPdfEncoding(round($e['process']), 2) . ' kg CO2e', 0, 1);
            $pdf->Cell(0, 8, 'Transport emissions: ' . toPdfEncoding(round($e['transport']), 2) . ' kg CO2e', 0, 1);
            $pdf->Cell(0, 8, 'Electricity emissions: ' . toPdfEncoding(round($e['electricity']), 2) . ' kg CO2e', 0, 1);
            $pdf->SetFont('Arial', 'B', 11);
            $pdf->Cell(0, 10, 'Step total: ' . round($e['total'], 2) . ' kg CO2e', 0, 1);
        }

        $pdf->Ln(5);
        $stepNumber++;
    }

    $pdf->SetFont('Arial', 'B', 14);
    $pdf->Cell(0, 10, 'Grand total: ' . round($grandTotal, 2) . ' kg CO2', 0, 1);

    $fileName = 'report_' . uniqid() . '.pdf';
    $filePath = __DIR__ . '/../reports/' . $fileName;
    $pdf->Output('F', $filePath);

    return 'reports/' . $fileName;
}


function calculateStepEmission(array $step): array
{
    $breakdown = ['material' => 0, 'process' => 0, 'transport' => 0, 'electricity' => 0, 'total' => 0];
    $weight = validateNumeric($step['quantity'] ?? 0);

    if (!empty($step['material_data'])) {
        foreach ($step['material_data'] as $material) {
            $isProcessed = ($material['material_name'] ?? '') === 'processed_material';
            $factor = $isProcessed ? 1 : floatval($material['emission'] ?? 0);
            $breakdown['material'] += $weight * $factor;
        }
    }

    if (!empty($step['process_data'])) {
        foreach ($step['process_data'] as $process) {
            $breakdown['process'] += $weight * floatval($process['emission'] ?? 0);
        }
    }

    foreach ($step as $key => $value) {
        if (strpos($key, 'transport') === 0 && strpos($key, '_data') !== false) {
            $index = str_replace(['transport', '_data'], '', $key);
            $distance = validateNumeric($step['distance' . $index] ?? 0);
            $weightTonnes = $weight / 1000;
            foreach ($value as $transport) {
                $efFixed = floatval($transport['ef_fixed'] ?? 0);
                $efMarginal = floatval($transport['ef_marginal'] ?? 0);
                $breakdown['transport'] += ($weightTonnes * $distance * $efMarginal) + $efFixed;
            }
        }
    }

    if (!empty($step['country_data'])) {
        $elecQty = validateNumeric($step['electricity'] ?? 0);
        foreach ($step['country_data'] as $country) {
            $breakdown['electricity'] += (floatval($country['carbon_intensity_g_kwh'] ?? 0) * $elecQty) / 1000;
        }
    }

    $breakdown['total'] = $breakdown['material'] + $breakdown['process'] + $breakdown['transport'] + $breakdown['electricity'];
    return $breakdown;
}

function validateNumeric($value): float
{
    if (!is_numeric($value) || floatval($value) <= 0) {
        throw new InvalidArgumentException('Invalid numeric value: ' . var_export($value, true));
    }
    return floatval($value);
}


$db = dbConnect();


if (!isset($_GET['request'])) {
    header('HTTP/1.1 400 Bad Request');
    echo json_encode(['error' => 'Missing request parameter']);
    exit;
}
$allowedRequests = ['raw_material', 'trip', 'electricity', 'process', 'save_steps'];
$request = $_GET['request'];

if (!in_array($request, $allowedRequests, true)) {
    header('HTTP/1.1 400 Bad Request');
    echo json_encode(['error' => 'Invalid request type']);
    exit;
}

//var_dump($request);

if ($request == 'raw_material'){
    $data = dbGetMaterials($db);
    //var_dump($data);
    header('Content-Type: application/json');
    echo json_encode($data);
    exit;
    if ($data === 0) {
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(null);
        exit;}

}

if ($request == 'trip'){
    $data = dbGetTransport($db);
    //var_dump($data);
    header('Content-Type: application/json');
    echo json_encode($data);
    exit;
    if ($data === 0) {
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(null);
        exit;}

}

if ($request == 'electricity'){
    $data = dbGetelectricity($db);
    header('Content-Type: application/json');
    echo json_encode($data);
    exit;
    if ($data === 0) {
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(null);
        exit;}

}

if ($request == 'process'){
    $data = dbGetprocess($db);
    header('Content-Type: application/json');
    echo json_encode($data);
    exit;
    if ($data === 0) {
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(null);
        exit;}

}

if (isset($_GET['request']) && $_GET['request'] == 'save_steps') {
    if (!isset($_POST['data'])) {
        header('HTTP/1.1 400 Bad Request');
        echo json_encode(['error' => 'Missing data']);
        exit;
    }

    $steps = json_decode($_POST['data'], true);

    if (json_last_error() !== JSON_ERROR_NONE || !is_array($steps)) {
        header('HTTP/1.1 400 Bad Request');
        echo json_encode(['error' => 'Invalid JSON payload']);
        exit;
    }

    $result = enrichSteps($db, $steps);

    $grandTotal = 0;
    try {
        foreach ($result as &$step) {
            $step['emissions'] = calculateStepEmission($step);
            $grandTotal += $step['emissions']['total'];
        }
        unset($step);
    } catch (InvalidArgumentException $e) {
        header('HTTP/1.1 400 Bad Request');
        echo json_encode(['error' => $e->getMessage()]);
        exit;
    }

    $reportPath = generateReport($result, $grandTotal);

    header('Content-Type: application/json');
    echo json_encode(['data' => $result, 'report' => $reportPath]);
    exit;
}

?>
