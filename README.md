# onebusaway-script

This is a collection of some scripts we're using to run OneBusAway in Austin. Feel free to copypasta whatever you'd like. Who knows if it works.

###  To use this script:

Choose combined or separate webapps. :warning: Combined currently does not work.

Inside will be either one or more data-sources.xml files (in xmlfiles folder for separate).

You must edit these to match your settings.

Once you have done this, you can optionally edit the script itself if you need to tweak it. All the variables are provided at the top for easier editing.

Then all you have to do is type:

```
cd separate
bash fresh_install_separate.sh
```

or

```
cd combined
bash fresh_install_combined.sh
```

to start the script!


## Requirements

For ubuntu 14, we needed to install:

```
sudo apt-get install git
sudo apt-get install openjdk-7-jdk
sudo apt-get install maven
```

You'll also need to set up a database and point the data-sources.xml to it. We used Postgres on AWS RDS.

## License

Released to the public domain under [the Unlicense](http://unlicense.org/).

To the extent possible under law, Vincent Liao and other Open Austin contributors have waived all copyright and related or neighboring rights to this work.
