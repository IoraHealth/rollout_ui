module RolloutUi
  class Wrapper
    class NoRolloutInstance < StandardError; end

    attr_reader :rollout

    def initialize(rollout = nil)
      @rollout = rollout || RolloutUi.rollout
      raise NoRolloutInstance unless @rollout
    end

    def groups
      rollout.instance_variable_get("@groups").keys
    end

    def add_feature(feature)
      unless rollout.features.include? feature.to_sym
        rollout.activate_percentage(feature, 0)
      end

      redis.sadd(:features, feature)
    end

    def remove_feature(feature)
      rollout_delete(feature)
      redis.srem(:features, feature)
    end

    def features
      features = redis.smembers(:features)
      features ? features.sort : []
    end

    def redis
      rollout.instance_variable_get("@storage")
    end

    # rollout added a delete method in 2.2.1
    # since we are using an older version inline the implementation here
    def rollout_delete(feature)
      # access rollout private methods
      features_key = rollout.send(:features_key)
      feature_key = rollout.send(:key, feature)

      # inlined copy of implementation from rollout.delete
      # https://github.com/FetLife/rollout/blob/master/lib/rollout.rb#L124
      features = rollout.features
      features.delete(feature)
      redis.set(features_key, features.join(","))
      redis.del(feature_key)
    end
  end
end
