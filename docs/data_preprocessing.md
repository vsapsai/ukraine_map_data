Here data preprocessing means taking data files in provided format and converting them to format suitable for [D3]( http://d3js.org/).  Specifically, we are taking a few [shapefiles](http://en.wikipedia.org/wiki/Shapefile) and convert them into a single [TopoJSON](https://github.com/mbostock/topojson) file.


## Preprocessing Steps

1. At first we convert each shapefile to [GeoJSON](http://geojson.org/) file.  Usually we perform some filtering at this step.  For example, we want data only for specific area, not for the entire world.  Or we may need data only for objects of certain size, like the biggest rivers.  Typically a shell command looks like

    ogr2ogr -f GeoJSON \
            -clipdst 20.5 43.6 42 53 \
            build/countries.json raw_data/ne_10m_admin_0_countries/ne_10m_admin_0_countries.shp

2. Then we convert each GeoJSON file to TopoJSON file.  At this step we decide which object properties will be available in JavaScript.  Mostly we are interested in `name`s and want to omit accessory properties like `note`, `comment`.  Typically a shell command looks like

    topojson -p name -o lakes.topo.json lakes.json

3. At the end we merge all TopoJSON files into a single TopoJSON file.  A shell command looks like

    topojson -p -o full.topo.json countries.topo.json regions.topo.json …


## Environment

The easiest way to install all necessary tools is by using a virtual machine.  You can use [VirtualBox](https://www.virtualbox.org/) as a virtualization software and [Vagrant](http://www.vagrantup.com/) to manage your environment.  You perform data preprocessing with the following shell commands:

1. Run `vagrant up` in `ukraine_map_data` to start the virtual machine.  The first time you need to wait until the virtual machine is downloaded and all necessary tools are installed.

2. Run `vagrant ssh` and in the virtual machine `cd /vagrant`.  At this point you see in the virtual machine the same files as in the host machine.

3. Run `rake` to create resulting TopoJSON file `build/full.topo.json`.

4. In the end exit the virtual machine with `exit` and shutdown it with `vagrant halt`.
