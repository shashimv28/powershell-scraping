#author :   shashidhar mulakaluri
#desc   :   webscraping with powershell

$dir_root= "$HOME/Documents/gitworkspace/powershell-scraping/"
$dir_bin="$dir_root/bin"
$dir_dat="$dir_root/dat"
$dir_log="$dir_root/log"
$dir_abs="$dir_root/abs"
$dir_rba="$dir_root/rba"
$dir_apra="$dir_root/apra"

cd $dir_bin
$cfgstr=Get-Content config.json | ConvertFrom-Json
$extname=Get-Date -UFormat "log_%Y%m%d_%H%M%S"
$logfile="$extname.log"

Start-Transcript -Path "$dir_log/$logfile"
try
{
    function download
    {
        param ($d_url , $d_source)
        if ($d_source -eq "abs")
        {
            cd $dir_abs
            $d_fname = $d_url -replace "&amp;", "#"
            $d_fname = $d_fname.split("#")[1]
            $d_fname = $d_f_name -replace " ", "_"
            $d_url = $d_url -replace "&amp;", "&"
            Invoke-WebRequest "$d_url" -OutFile $d_fname
            echo "Downloaded : $d_fname to $dir_abs"
        }
        elseif ($d_source -eq "rba")
        {
            cd $dir_rba
            $d_fname = $d_url.split("/")[-1]
            $d_url = $d_url -replace "&amp;", "&"
            Invoke-WebRequest "$d_url" -OutFile $d_fname
            echo "Downloaded : $d_fname to $dir_rba"
        }
        elseif ($d_source -eq "apra")
        {
            cd $dir_abs
            $d_fname = $d_url -replace "%2520", "_"
            $d_fname = $d_fname -replace "%20", "_"
            $d_fname = $d_url.split("/")[-1]
            $d_url = $d_url -replace "&amp;", "&"
            Invoke-WebRequest "$d_url" -OutFile $d_fname
            echo "Downloaded : $d_fname to $dir_apra"
        }
        cd $dir_bin
    }

    function extraction
    {
        param ($e_url , $e_url_prefix , $e_url_root, $e_source )
        echo $e_url
        $WebResponse = Invoke-WebRequest "$e_url"
        ForEach ($item in $WebResponse.Links)
        {
            if ($item.href | Select-String -Pattern '.csv' -SimpleMatch)
            {
                $href=$item.href
                $url="$e_url_root$href"
                download -d_url $url -d_source $e_source
            }
            elseif ($item.href | Select-String -Pattern '.xls' -SimpleMatch)
            {
                $href=$item.href
                $url="$e_url_root$href"
                download -d_url $url -d_source $e_source
            }
            elseif ($item.href | Select-String -Pattern '.xlsx' -SimpleMatch)
            {
                $href=$item.href
                $url="$e_url_root$href"
                download -d_url $url -d_source $e_source
            }
            elseif ($item.href | Select-String -Pattern '.pdf' -SimpleMatch)
            {
                $href=$item.href
                $url="$e_url_root$href"
                download -d_url $url -d_source $e_source
            }
            elseif ($item.href | Select-String -Pattern '.zip' -SimpleMatch)
            {
                $href=$item.href
                $url="$e_url_root$href"
                download -d_url $url -d_source $e_source
            }
        }
    }

    function getUrl
    {
        param ($e_url , $e_url_prefix , $e_url_root)
        $WebResponse = Invoke-WebRequest "$e_url"
        $latest_url=""
        ForEach ($link in $WebResponse.Links)
        {
            if ($link.outerText | Select-String -Pattern 'Latest' -SimpleMatch)
            {
                $href=$link.href
                $latest_url="$s_url_prefix/$href"
            }
        }

        $WebResponse = Invoke-WebRequest "$latest_url"
        $downloads_url = ""

        ForEach ($link in $WebResponse.Links)
        {
            if ($link.outerText | Select-String -Pattern 'Downloads' -SimpleMatch)
            {
                $href=$link.href
                $downloads_url="$s_url_root/$href"
            }
        }

        return $downloads_url
    }

    ForEach ($src in $cfgstr.sources)
    {
        $source = $src.source
        $series=$src.series
        $url_root = $src.url_root
        $url_prefix = $src.url_prefix
        $url_updates = $src.url_updates
        $url_series = $src.url_series

        echo "`n"
        if ($source -eq "abs")
        {
            $ext_url = getUrl -s_url "$url_prefix$url_series" -s_url_prefix $url_prefix -e_url_root $url_root
            extraction -eurl $ext_url -e_url_prefix $url_prefix -e_url_root "$url_root/" -e_source $source
        }
        elseif ($source -eq "rba")
        {
            $ext_url = "$url_prefix$url_series"
            extraction -eurl $ext_url -e_url_prefix $url_prefix -e_url_root "$url_root/" -e_source $source
        }
        elseif ($source -eq "apra")
        {
            $ext_url = "$url_prefix$url_series"
            $url_root=""
            extraction -eurl $ext_url -e_url_prefix $url_prefix -e_url_root "$url_root" -e_source $source
        }

        echo "`n"
    }
}
catch
{
    echo $Error
}
Stop-Transcript