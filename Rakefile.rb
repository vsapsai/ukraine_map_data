require 'rake/clean'

# Set to true to print extra data during build.  Useful for debugging Rakefile.rb itself.
DEBUG_BUILD = true

OUTPUT_DIRECTORY = 'build'
RAW_DATA_DIRECTORY = 'raw_data'

DEFAULT_REGION = "20.5 43.6 42 53"

# Returns path to reference data file `file_name`.
def reference_input(file_name)
    File.join(RAW_DATA_DIRECTORY, 'reference_data', file_name)
end

# Returns path for GeoJSON file corresponding to `task_symbol`.
def geojson_output(task_symbol)
    File.join(OUTPUT_DIRECTORY, task_symbol.to_s + '.json')
end

# Returns path for TopoJSON file corresponding to `task_symbol`.
def topojson_output(task_symbol)
    File.join(OUTPUT_DIRECTORY, task_symbol.to_s + '.topo.json')
end

task :output_prepare do
    FileUtils.mkdir_p(OUTPUT_DIRECTORY)
end

# Create a task for generating 'output' from 'inputs' using a shell command
# 'command'.  'output' is updated when either one of 'inputs' is updated or
# when command to create 'output' has changed.
def shell_command_task(output, inputs, command)
    output_command_file = output + '.cmd.txt'
    task output => [:output_prepare] + inputs do
        is_command_same = File.exist?(output_command_file) && (command == IO.read(output_command_file))
        is_output_stale = !is_command_same || !uptodate?(output, inputs)
        if is_output_stale
            if DEBUG_BUILD
                puts command
            end
            # Clear existing output because ogr2ogr doesn't support overriding existing file.
            if File.exist?(output)
                FileUtils.remove_file(output)
            end
            successfully = system(command)
            if !successfully
                raise "Failed command '#{command}'"
            end
            if !is_command_same
                IO.write(output_command_file, command)
            end
        end
    end

    CLEAN.push(output_command_file)
end

# Create tasks to generate TopoJSON file from .shp file.
def topo_task(task_symbol, geo_data_name, args={})
    shape_file = File.join(RAW_DATA_DIRECTORY, geo_data_name, geo_data_name + '.shp')
    geojson_file = geojson_output(task_symbol)
    topojson_file = topojson_output(task_symbol)

    geojson_command = "ogr2ogr -f GeoJSON #{args.fetch(:geo_args, '')} #{geojson_file} #{shape_file}"
    topojson_command = "topojson #{args.fetch(:topo_args, '')} -o #{topojson_file} #{geojson_file}"

    # .shp |> .json |> .topo.json.  Dependency is in the opposite order, naturally.
    shell_command_task(geojson_file, [shape_file], geojson_command)
    shell_command_task(topojson_file, [geojson_file], topojson_command)
    task task_symbol => topojson_file

    CLEAN.push(geojson_file)
    CLEAN.push(topojson_file)
end

# Create task(s) to generate TopoJSON file with some extra data added to an existing TopoJSON file.
def topo_edit_data_task(task_symbol, dependent_task_symbol, property_rule, join_rule, external_data_file_name)
    input_file = topojson_output(dependent_task_symbol)
    result_file = topojson_output(task_symbol)

    command = "topojson_edit/add_regions_data --input #{input_file}" +
        " --extra-data #{external_data_file_name} --output #{result_file}"

    shell_command_task(result_file, [input_file, external_data_file_name], command)
    task task_symbol => result_file

    CLEAN.push(result_file)
end

# Create tasks to merge a few TopoJSON files into a single TopoJSON file.
# Properties from merged files are preserved.
def topo_merge_task(task_symbol, dependent_tasks)
    result_file = topojson_output(task_symbol)
    dependent_files = dependent_tasks.map { |task| topojson_output(task) }
    command = "topojson -p -o #{result_file} #{dependent_files.join(' ')}"
    shell_command_task(result_file, dependent_files, command)
    task task_symbol => dependent_tasks + [result_file]

    CLOBBER.push(result_file)
end

topo_task :countries, 'ne_10m_admin_0_countries', {
    :geo_args => "-clipdst #{DEFAULT_REGION}",
    :topo_args => "--id-property ADM0_A3 -p name=NAME -p name"}

topo_task :regions, 'ne_10m_admin_1_states_provinces', {
    :geo_args => %{-where "ADM0_A3 = 'UKR' AND name NOT IN ('Sevastopol', 'Kiev City')"},
    :topo_args => '-p name'}

topo_edit_data_task :regions_with_id, :regions, 'id=domain_name', 'name=name', reference_input('regions_data.json')

topo_task :lakes, 'ne_10m_lakes', {
    :geo_args => "-clipdst #{DEFAULT_REGION}" + ' -where "scalerank < 8"',
    :topo_args => '-p name'}

topo_task :rivers, 'ne_10m_rivers_lake_centerlines', {
    :geo_args => %{-clipdst #{DEFAULT_REGION} -where "scalerank < 5 AND featurecla != 'Lake Centerline'"},
    :topo_args => '-p name'}

topo_merge_task(:full, [:countries, :regions_with_id, :lakes, :rivers])
task :default => :full
