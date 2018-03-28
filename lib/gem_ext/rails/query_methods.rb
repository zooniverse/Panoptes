# Backported .or query methods from Rails 5.0
# https://github.com/rails/rails/pull/16052/files

if Gem::Version.new(Rails.version) < Gem::Version.new("5.0")
  ActiveRecord::QueryMethods.module_eval do

    # Returns a new relation, which is the logical union of this relation and the one passed as an
    # argument.
    #
    # The two relations must be structurally compatible: they must be scoping the same model, and
    # they must differ only by +where+ (if no +group+ has been defined) or +having+ (if a +group+ is
    # present). Neither relation may have a +limit+, +offset+, or +uniq+ set.
    #
    # Post.where("id = 1").or(Post.where("id = 2"))
    # # SELECT `posts`.* FROM `posts` WHERE (('id = 1' OR 'id = 2'))
    #
    def or(other)
      spawn.or!(other)
    end

    def or!(other)
      combining = group_values.any? ? :having : :where
      unless other.is_a?(ActiveRecord::NullRelation)
        left_values = send("#{combining}_values")
        right_values = other.send("#{combining}_values")
        common = left_values & right_values
        mine = left_values - common
        theirs = right_values - common
        if mine.any? && theirs.any?
          mine = mine.map { |x| String === x ? Arel.sql(x) : x }
          theirs = theirs.map { |x| String === x ? Arel.sql(x) : x }
          mine = [Arel::Nodes::And.new(mine)] if mine.size > 1
          theirs = [Arel::Nodes::And.new(theirs)] if theirs.size > 1
          common << Arel::Nodes::Or.new(Arel::Nodes::Grouping.new(mine.first), Arel::Nodes::Grouping.new(theirs.first))
        end
        send("#{combining}_values=", common)
        bind_values.concat(other.bind_values)
      end
      self
    end
  end

  ActiveRecord::Querying.module_eval do
    delegate :or, to: :all
  end
end
