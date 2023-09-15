#!/bin/bash

#colors
END="\e[1m"
Red="\e[31m"
BOLDRED="\e[1m${Red}"
GREEN="\e[32m"
BOLDGREEN="\e[1m${GREEN}"
YELLOW="\033[0;33m"
Cyan="\e[0;36m"
BOLDCYAN="\e[1m${Cyan}"
white="\e[0;37m"

#banner for Script to look cool
function banner {
        echo -e "
${BOLDRED}
 #####   ######   ####    ####   #    #    ##     ####
 #    #  #       #    #  #    #  ##   #   #  #   #
 #    #  #####   #       #    #  # #  #  #    #   ####
 #####   #       #       #    #  #  # #  ######       #
 #   #   #       #    #  #    #  #   ##  #    #  #    #
 #    #  ######   ####    ####   #    #  #    #   ####   v1

                                                        twitter:0xanas
                                                        by @Anas_Ibrahim ${white}"
}

#Check for the help option
if [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
        banner
        echo "Usage:
        $0 [options]
Options:
        -h   ,  --help            Print this help message.
        -d   ,  --domain          Check the domain format.
        -tf  ,  --token_file      Enter a file includes github token.
        -sub ,  --subdomain       Enter subdomain to recon it.
        "
        exit 0
fi

# Check if the user entered any options
if [ $# -eq 0 ]; then
        banner
        echo "Please specify an option.
Use -h for help.
        "
        exit 1
fi

#Check if the user entered the -d option
if [[ $1 == "-d" ]] || [[ $1 == "--domain" ]]; then
        
        if [ $# -eq 1 ]; then
                echo -e "${Red} Error: -d/--domain option requires an argument ${white}"
                exit 1
        fi

        # Check if the user also entered the -tf option
        if [[ $3 == "-tf" ]] || [[ $3 == "--token_file" ]]; then

                # Check if the user entered a file name after the -tf option
                if [ $# -eq 4 ]; then
                        banner
                        domain=$2
                        
                        if [[ ! $domain =~ ^[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)+$ ]]; then
                                echo "Invalid domain format."
                                exit 1
                        fi
                         
                        # Get the current date and time.
                        current_date=$(date "+%Y-%m-%d %H:%M:%S")
                        echo -e "[${BOLDCYAN}INFO${white}] The current date and time: ${BOLDGREEN}$current_date ${white}"

                        #Creating info directory
                        mkdir info

                        # Get the IP address of the domain
                        echo -e "${BOLDCYAN}################# Identifying Domain IP ################# ${white}\n"
                        dig +short $domain | tee info/domain_ips.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/info/domain_ips.txt ${white}\n"
                        
                        #Get CIDRs
                        echo -e "${BOLDCYAN}################# Identifying Domain CIDRs ################# ${white}\n"
                        asnmap -i $PWD/info/domain_ips.txt -silent | tee info/cidrs.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/info/cidrs.txt ${white}\n"

                        #Get info using host command
                        echo -e "${BOLDCYAN}################# Scanning host to get NS,MX,TXT,CNAME Records ################# ${white}\n"
                        host -t any $domain | tee -a info/host.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/info/host.txt ${white}\n"

                        #Get info using whois command
                        echo -e "${BOLDCYAN}################# Collecting info from the target ################# ${white}\n"
                        whois $domain | tee -a info/whois.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/info/whois.txt ${white} \n"

                        echo  -e "${BOLDCYAN}################# DNS Enumeration ################# ${white}\n"
                        dnsrecon -d $domain | tee info/dnsrecon.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/info/dnsrecon.txt ${white} \n"

                        echo -e "${BOLDCYAN}################# Collecting name servers ################# ${white}\n"
                        dnsrecon -d $domain | grep 'NS ' | cut -d ' ' -f 4 | tee info/name_servers.txt
                        echo -e "\n${BOLDCYAN} [+] The Name Servers saved in: ${BOLDGREEN}$PWD/info/name_servers.txt ${white}\n"

                        echo -e "${BOLDCYAN}################# Scanning Zone Transfer ################# ${white}\n"
                        for name_server in $name_servers; do
                                host -l $domain $name_server | tee  info/zone_transfer.txt
                        done
                        echo -e "\n${BOLDCYAN} [+] Zone Transfer saved in: ${BOLDGREEN}$PWD/info/zone_transfer.txt ${white}\n"

                        #Get info using whatweb
                        echo -e "${BOLDCYAN}################# Identifying technologies of the target ################# ${white}\n"
                        whatweb -v -a 3 $domain| tee info/whatweb.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/info/whatweb.txt ${white}\n"

                        #Collecting emails
                        echo -e "${BOLDCYAN}################# Collecting leaked emails about the company ################# ${white}\n"
                        emailharvester -d $domain --noprint | tee info/emails.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/info/emails.txt ${white}\n"

                        
                        #creating subdomains directory
                        mkdir subdomains

                        # Collecting subdomains using subfinder
                        echo -e "${BOLDCYAN}################# Collecting Subdomains using subfinder ################# ${white}\n"
                        subfinder -d $domain -silent -o subdomains/subfinder.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/subdomains/subfinder.txt ${white}\n"

                        # Collecting subdomains using assetfinder
                        echo -e "${BOLDCYAN}################# Collecting Subdomains using assetfinder ################# ${white}\n"
                        assetfinder --subs-only $domain | tee subdomains/assetfinder.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/subdomains/assetfinder.txt ${white}\n"

                        # Collecting subdomains using amass
                        echo -e "${BOLDCYAN}################# Collecting Subdomains using amass ################# ${white}\n"
                        amass enum -passive -d $domain -o subdomains/amass.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/subdomains/amass.txt ${white}\n"

                        #Collecting subdomains using crt.sh website
                        echo -e "${BOLDCYAN}################# Collecting Subdomains using crt.sh ################# ${white}\n"
                        curl -s https://crt.sh/\?q\=\$domain\&output\=json | jq -r '.[].name_value' | grep -Po '(\w+\.\w+\.\w+)$' | tee subdomains/crt.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/subdomains/crt.txt ${white}\n"
                        # Merging all the results into one file
                        cat subdomains/*.txt | sort -u | tee subdomains/all_subs.txt

                        #Collecting Live Subdomains
                        echo -e "${BOLDCYAN}################# Collecting Live Subdomains ################# ${white}\n"
                        cat subdomains/all_subs.txt | httpx -mc 200,201,202,203,300,301,302,303,401,403 -silent | tee subdomains/live_subs.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/subdomains/live_subs.txt ${white}\n"

                        #Creating ip directory
                        mkdir ip

                        #Converting live subdomains into IPs
                        echo -e "${BOLDCYAN}################# Converting Live Subdomains into IPs ################# ${white}\n"
                        cat $PWD/subdomains/live_subs.txt | cut -d "/" -f 3 | while read line ; do host -t A $line ; done | grep "has address" | cut -d " " -f 4 | sort -u | tee ip/live_ips.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/ip/live_ips.txt ${white}\n"


                        #Scanning live IPs using naabu command concatenated wit nmap
                        echo -e "${BOLDCYAN}################# Scanning Live Subdomains ################# ${white}\n"
                        cat $PWD/ip/live_ips.txt | naabu -nmap-cli 'nmap -sV -oX ip/nmap_output.txt'
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/ip/nmap_output.txt ${white}\n"

                        #Shodan dorking 
                        echo -e "${BOLDCYAN}################# Shodan dorks ################# ${white}\n"
                        #Creating shodan directory
                        mkdir shodan

                        #Extract domain name without tld
                        echo $domain | cut -d '.' -f 1 | tee tld.txt
                        tld=$(cat tld.txt)
                        #Define the dorks
                        dorks=(
                                "$domain"
                                "$domain port:80"
                                "$domain port:21"
                                "$domain port:22"
                                "$domain port:25"
                                "$domain port:8080"
                                "$domain port:53"
                                "$domain port:3306"
                                "hostname:$domain"
                                "ssl:$domain"
                                "ssl.cert.issuer.cn:$domain"
                                "ssl.cert.subject.cn:$domain"
                                "org:$tld 'MongoDB Server Information' port:27017 -authentication"
                                "org:$tld 'Set-Cookie: mongo-express=' '200 OK'"
                                "org:$tld mysql port:'3306'"
                                "org:$tld port:5432 PostgreSQL"
                                "org:$tld port:'9200' all:'elastic indices'"
                                "org:$tld proftpd port:21"
                                "org:$tld port:21 vsftpd 3.0.3"
                                "org:$tld '230 Login successful.' port:21"
                                "org:$tld openssh port:22"
                                "org:$tld port:'23'"
                                "org:$tld port:'25' product:'exim'"
                                "org:$tld port:'11211' product:'Memcached'"
                                "org:$tld 'X-Jenkins' 'Set-Cookie: JSESSIONID' http.title:'Dashboard'"
                                "org:$tld 'port:53' Recursion: Enabled"
                                "org:$tld product:'Apache httpd' port:'80'"
                                "org:$tld product:'Microsoft IIS httpd'"
                                "org:$tld product:'nginx'"
                                "org:$tld port:8080 product:'nginx'"
                                "org:$tld remote desktop 'port:3389'"
                                "org:$tld 'authentication disabled' 'RFB 003.008'"
                                "org:$tld 'Authentication: disabled' port:445"
                        )

                        # Loop through the dorks
                        for dork in "${dorks[@]}"; do
                                echo "------------------------------------------------"
                                # Print the dork name
                                echo -e "${BOLDCYAN} [+] Searching for dork : ${YELLOW} $dork ${white}"

                                # Run the Shodan search command
                                shodan search --fields ip_str,port,org,hostnames,transport "$dork" | tee -a $dork.txt

                                echo -e "${BOLDCYAN} [+] The results of ${YELLOW} $dork ${BOLDCYAN} saved in ${boldgreen} $dork.txt ${white}"
                                #Print the number of lines in the file
                                lines=$(wc -l "$dork.txt")
                                echo -e "${BOLDCYAN} [+] The number of IPs founded using this dork ${YELLOW} '$dork'${BOLDCYAN} is :${BOLDGREEN} $lines ${white}"
                                echo "--------------------------------------------------"
                        done
                                    

                        #Creating github directory
                        mkdir github

                        #github dorks
                        echo -e "${BOLDCYAN}################# Github Dorks ################# ${white}\n"
                        gitdorks_go -gd $PWD/files/allgithub.txt -nws 20 -target $2 -tf $PWD/files/token.txt -ew 3 | tee github/github_dorks.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/github/github_dorks.txt ${white}\n"

                        
                        #Creating vulns directory
                        mkdir vulns

                        #Subdomain takeover
                        echo -e "${BOLDCYAN}################# Subdomain Takeover ################# ${white}\n"
                        subzy run --targets $PWD/subdomains/all_subs.txt | tee vulns/sub_takeover.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/vulns/sub_takeover.txt ${white}\n"

                        #cors misconfiguration
                        echo -e "${BOLDCYAN}################# CORS Misconfiguration ################# ${white}\n"
                        corscanner -i $PWD/subdomains/live_subs.txt -o vulns/cors.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/vulns/cors.txt ${white}\n"

                        #CRLF Injection
                        echo -e "${BOLDCYAN}################# CRLF Injection ################# ${white}\n"
                        crlfuzz -l $PWD/subdomains/live_subs.txt -s -o vulns/crlf.txt
                        echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/vulns/crlf.txt ${white}\n"

                
                else
                        echo -e "${Red} Error: The file name must be specified after the -tf/--token_file option. ${white}"
                        exit 1
                fi
        else
                echo -e "${Red} Error: The -tf/--token_file option is required after the -d option. ${white}"
                exit 1
        fi
fi




#Doing subdomain recon while using -sub option
if [[ $1 == "-sub" ]] || [[ $1 == "--subdomain" ]]; then

        if [ $# -eq 2 ]; then
                banner
                subdomain=$2

                # Get the IP address of the domain
                ip=$(dig +short $subdomain)
                echo -e "The IP address of ${BOLDCYAN}$subdomain ${white}is ${BOLDGREEN}$ip ${white}\n"

                #Collecting parameters using paramspider
                echo -e "${BOLDCYAN}################# Collecting parameters ################# ${white}\n"
                paramspider -d $subdomain -s | tee param1.txt
                echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/param1.txt ${white}\n"

                #Collecting parameters using arjun
                echo -e "${BOLDCYAN}################# Collecting hidden parameters ################# ${white}\n"
                arjun -u http://$subdomain | tee param2.txt
                echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/param2.txt ${white}\n"

                #Fuzzing directories
                echo -e "${BOLDCYAN}################# Directory Fuzzing ################# ${white}\n"
                dirsearch -u http://$subdomain | tee dir.txt
                echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/dir.txt ${white}\n"

                #Fuzzing directories
                echo -e "${BOLDCYAN}################# Fuzzing backup files ################# ${white}\n"
                dirsearch -u http://$subdomain -w $PWD/files/backup_files_only.txt | tee backup.txt
                echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/backup.txt ${white}\n"

                #Collecting directories and files from archive
                echo -e "${BOLDCYAN}################# Wayback Archive ################# ${white}\n"
                echo "$subdomain" | waybackurls | tee archive.txt
                echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/archive.txt ${white}\n"

                #Collecting JS Files
                echo -e "${BOLDCYAN}################# Collecting and Scanning JS Files ################# ${white}\n"
                cat $PWD/archive.txt | grep ".js" | tee js.txt
                subjs -i js.txt | tee js_scan.txt
                echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/archive.txt ${white}\n"

                #Collecting possible vulnerable links
                echo -e "${BOLDCYAN}################# Collecting Possible Vulnerable XSS Links ################# ${white}\n"
                cat $PWD/param1.txt $PWD/param2.txt $PWD/archive.txt | gf xss | tee xss_params.txt
                #Scanning XSS
                echo -e "${BOLDCYAN}################# Scanning XSS ################# ${white}\n"
                cat xss_params.txt | kxss | tee xss_scan.txt
                echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/xss_scan.txt & $PWD/xss_params.txt ${white}\n"

               
                #Collecting possible vulnerable links
                echo -e "${BOLDCYAN}################# Collecting Possible Vulnerable SQLi Links ################# ${white}\n"
                cat $PWD/param1.txt $PWD/param2.txt $PWD/archive.txt | gf sqli | tee sqli_params.txt
                
                #Collecting possible vulnerable links
                echo -e "${BOLDCYAN}################# Collecting Possible Vulnerable SSRF Links ################# ${white}\n"
                cat $PWD/archive.txt | gf ssrf > sqli_params.txt
                echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/ssrf_params.txt ${white}\n"

                #Collecting possible vulnerable links
                echo -e "${BOLDCYAN}################# Collecting Possible Vulnerable LFI Links ################# ${white}\n"
                cat $PWD/archive.txt | gf ssrf > sqli_params.txt
                echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/lfi_params.txt ${white}\n"

                #Collecting possible vulnerable links
                echo -e "${BOLDCYAN}################# Collecting Possible Vulnerable IDOR Links ################# ${white}\n"
                cat $PWD/archive.txt | gf ssrf > sqli_params.txt
                echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/idor_params.txt ${white}\n"

                #Collecting possible vulnerable links
                echo -e "${BOLDCYAN}################# Collecting Possible Vulnerable Redirect Links ################# ${white}\n"
                cat $PWD/archive.txt | gf ssrf > sqli_params.txt
                echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/redirect_params.txt ${white}\n"

                #Scanning nmap
                echo -e "${BOLDCYAN}################# Port Scanning ################# ${white}\n"
                nmap $ip -T4 -sV -Pn -o nmap.txt
                echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/nmap.txt ${white}\n"

                #nuclei scan
                echo -e "${BOLDCYAN}################# Finding Bugs from archive ################# ${white}\n"
                cat archive.txt | nuclei | tee nuclei1.txt
                echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/nuclei1.txt ${white}\n"

                #nuclei scan
                echo -e "${BOLDCYAN}################# Finding Bugs from parameters ################# ${white}\n"
                cat params*.txt | nuclei | tee nuclei2.txt
                echo -e "\n${BOLDCYAN} [+] Results saved in ${BOLDGREEN} $PWD/nuclei2.txt ${white}\n"

                #Creating results directory
                mkdir results
                sudo mv *.txt results
        else
                echo -e "${Red} Error: The -sub option requires an argument. ${white}"
                exit 1
        fi
fi
