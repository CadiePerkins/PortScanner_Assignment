####### Port Scanner Script -- PowerShell #######

    # To run this script, call the script and enter the desired host IP address (ex: .\portscanner.ps1 192.168.1.0)

param($hosts)

# Functions for different methods
Function ICMP-method($theHost){
    $ping = Read-Host -Prompt 'Would you like to use ICMP to reach your host? y/n'

    if($ping -eq 'y'){
        Test-NetConnection -ComputerName $theHost -InformationLevel Detailed
    } else{
        Write-Host "Okay, maybe next time!"
    }
}

Function traceroute-method($theHost){
    $traceroute = Read-Host "Would you like to do a traceroute? y/n"
       
    if($traceroute -eq "y"){
        Test-NetConnection -TraceRoute $theHost
    }
    else{
        Write-Host "Okay, maybe next time!"
    }
}

Function tcp-method($theHost,$port){
    try{ #tests to see if a connection can be made to a tcp port
        $socket = New-Object System.Net.Sockets.TcpClient
        $socket.ReceiveTimeout = 200
        $socket.SendTimeout = 200
        $socket.Connect($theHost,$port)
        Write-Host "Port $port is open!"
        $socket.Close()
    }
    catch
    {
        Write-Host "Cannot connect! Port $port is closed, filtered, or otherwise inaccessible."
        $_.Exception.Message
    }
}

Function udp-method($theHost,$port){
    #tests to see if a connection can be made or a UDP packet is accepted to the given port
    $socket = New-Object System.Net.Sockets.UdpClient
    $socket.Client.ReceiveTimeout = 200
    $socket.Connect($theHost,$port)
    [void]$socket.Send(1,1) #the packet sent to the port (1 byte)
    $test = New-Object System.Net.IPEndPoint([System.Net.IPaddress]::Any,0)

    try {
        if ($socket.Receive([ref]$test)) {
            Write-Host "Port $port is open!"
            $socket.Close()
        }
    } catch {
        Write-Host "Cannot connect! Port $port is closed, filtered, or otherwise inaccessible."
    }
}

# The Port Scanning function
Function port-scanner($theHost){
    # ICMP (ping) on host? y/n
    ICMP-method $theHost 

    # Traceroute? y/n
    traceroute-method $theHost

    # Scan single or multiple ports?
    $portNum = Read-Host "Would you like to scan a single port or multiple? single/multiple"

    if($portNum -eq "single"){
        [int]$port = Read-Host -Prompt 'What port would you like to scan? i.e. 80'

        # Single port: Use TCP or UDP method?
        $method = Read-Host "Would you like to use TCP or UDP? tcp/udp"

        if($method -eq "udp"){
            #UDP: Single port, udp function
            udp-method $theHost $port
        }
        elseif($method -eq "tcp"){
            #TCP: Single port, tcp function
            tcp-method $theHost $port
        } else{
            Write-Host "Please choose either tcp or udp."
            return
        }
        
    }
    elseif($portNum -eq "multiple"){
        # Get how many and which ports user wants to scan
        [int]$number = Read-Host -Prompt 'How many ports would you like to scan? i.e. 3'
        $ports = @()
        for($count=1; $count -lt $number+1; $count++){
            [int]$answer = Read-Host -Prompt 'Which port would you like to scan? i.e. 80'
                "Port $count of $number - $answer"
                $ports += $answer
        }
        
        # Multiple ports: Use TCP or UDP?
        $method = Read-Host "Would you like to use TCP or UDP? tcp/udp"
        
        if($method -eq "udp"){
            #UDP: Single host, multiple ports, udp code
            foreach($p in $ports){
                udp-method $theHost $p
            }
        }
        elseif($method -eq "tcp") {
            #TCP: Single host, multiple ports, tcp code
            foreach($p in $ports){
                tcp-method $theHost $p
            }
        } else{
            Write-Host "Please choose either tcp or udp."
            return
        }   
    }
    else {
        Write-Host "Please enter single or multiple."
        return
    }
}    

# Call the function
port-scanner $hosts