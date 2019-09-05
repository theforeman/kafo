module Kafo
  class HieraConfigurer
    def self.default_config
      {
        'version' => 5,
        'hierarchy' => [
          {
            'name' => 'Kafo Answers',
            'path' => '%{facts.kafo.scenario.answer_file}',
            'data_hash' => 'yaml_data',
          },
        ],
      }
    end

    def self.write_default_config(path)
      File.open(path, 'w') { |f| f.write(YAML.dump(default_config)) }
      path
    end

    def self.generate_data(modules, order = nil)
      classes = []
      data = modules.select(&:enabled?).inject({}) do |config, mod|
        classes << mod.class_name
        config.update(Hash[mod.params_hash.map { |k, v| ["#{mod.class_name}::#{k}", v] }])
      end
      data['classes'] = sort_modules(classes, order)
      data
    end

    def self.sort_modules(modules, order)
      return modules unless order

      (order & modules) + (modules - order)
    end
  end
end
