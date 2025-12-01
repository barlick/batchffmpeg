Welcome to the batchffmpeg linux ffmpeg based batch video file transcoding application.

![alt text](https://github.com/barlick/batchffmpeg/blob/main/batchffmpeg_screenshot.png)

This is for use with linux and uses "ffmpeg" to do the transcoding.

I coded and tested this using Arch linux but it should work OK on other distros such as Debian, Ubuntu, Linux Mint etc. as long as "ffmpeg" is installed.

I wrote this because I only occasionally need to convert batches of video files in various formats to a standard ".mkv" format and whilst I have written bash scripts to do this, 
I have to find those scripts, check them to confirm they are the "right" versions of the scripts and run a test before risking actually letting them loose on my video files 
so having a simple GUI app to to this for me is more convenient.

I have tried various other "batch video file conversion/transcoding" linux apps and whilst "ffqueue" is pretty good (I recommend that you try that before using batchffmpeg because it's probably
better for most people's general use cases) I found it over complicated and I wanted a much simpler workflow and greater control over the ffmpeg run parameters because I already knew the optimal settings 
to use hardware acceleration for my video card etc.

So that's why "batchffmpeg" exists and I've found it does exactly what I want (and nothing more) so I've published it in case someone else might find it useful.

I've included a screenshot of "batchffmpeg" running on Debian + KDE as "batchffmpeg_screenshot.png".

As you can see it's very simple i.e. select the source video file types, the source video folder, the target video file type, the target output folder, whether or not you want to delete successfully
converted source video files after conversion, select the required video files detected in the source folder, click "Start" and leave it to run.

The GUI is quite intuitive and the target folder tracks with the selected source folder as I usually want the converted video files to be in the same source folder unless I specifically select a 
different target folder. It also saves your settings to ~/.config/batchffmpeg.conf which avoids having to re-input the various settings every time you use it.

As for the "ffmpeg parameters", I've defaulted it to: ffmpeg -i "<source file>" -global_quality 22 -init_hw_device vaapi=amd:/dev/dri/renderD129 -vf "format=nv12|vaapi,hwupload"  -c:v h264_vaapi "<target file>"
because that's what works best for MY specific hardware configuration.
I suggest you change that to the simple version: ffmpeg -i "<source file>" "<target file>"
That pretty much guaranteed to work on any system so it's good for testing purposes but obviously you need to read the ffmpeg documentation (and or search for "ffmpeg parameters for <name of your video card>"
to find optimised values that work well for you.

It makes a note of the run start time and the size of the selected source video files and after successfully converting each source file it gives an estimated "time remaining" and expected completion time.
That fairly accurate so if (for example) you were converting 20 ".avi" files of roughly the same size to ".mkv" and started at 10:00am and it completed conversion of the first file after 5 minutes then it would
project an estimated completion time for all 20 files as (5 minutes * 19) = 95 minutes remaining and an expected completed time as 11:35am.
That's a key feature for me as I can get on with something else knowing that I can leave batchffmpeg to get on with the job and not bother checking in on it until after the estimated completion time.

OK, moving on to actually installing "batchffmpeg":

Required packages:

ffmpeg:

To install ffmpeg on Arch: sudo pacman -S ffmpeg
To install ffmpeg on Debian/Ubuntu type distro: sudo apt install ffmpeg

Installing "batchffmpeg" itself:

Lazarus:

The batchffmpeg app was written using the Lazarus Free Pascal IDE.
If you want to compile batchffmpeg yourself then you will need to install Lazarus. Please follow the documentation on their website: https://www.lazarus-ide.org/ 
Note: As at time of writing (August 2025) these terminal commands should work:
To install lazarus on Arch: 
sudo pacman -Sy lazarus
sudo pacman -Sy lazarus-qt5
To install lazarus on Debian/Ubuntu type distro: 
sudo apt install make gdb fpc fpc-source lazarus-ide-qt5 lcl-gtk2 lcl-qt5
You should then be able to run the Lazarus IDE app, load the project file "batchffmpeg.lpr" and compile it.

If you don't want to install Lazarus and compile batchffmpeg yourself then you can just take the x86 binary "batchffmpeg" from the batchffmpeg repo and use that instead.
You will need to copy the batchffmpeg app binary file to a suitable folder e.g. "/usr/local/bin/".
You will also need to make it executable so run "sudo chmod +x /usr/local/bin/batchffmpeg" in the terminal.
You can then try running it from the terminal by typing "batchffmpeg" to confirm that it runs OK. 
If the batchffmpeg app won't run from the terminal then I *think* that if you install the "qt5pas" package then that should allow the batchffmpeg binary to run:
To install qt5pas on Arch: sudo pacman -S qt5pas   
To install qt5pas on Debian/Ubuntu type distro: sudo apt install qt5pas

Once it's working from the terminal then you can (sudo) copy the "batchffmpeg.desktop" file from the batchffmpeg repo to your /usr/share/applications folder which should allow you to launch batchffmpeg
from your application launcher/menu.

Have fun!
