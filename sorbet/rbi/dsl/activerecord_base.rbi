# typed: strict

module ActiveRecord
  class Base
    extend T::Sig

    sig { returns(T.untyped) }
    def self.connection; end
  end

  class Relation
    extend T::Sig

    sig { returns(String) }
    def to_sql; end

    sig { returns(T.untyped) }
    def explain; end
  end
end