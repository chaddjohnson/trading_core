class ActiveRecord::Relation
  def raw
    connection.execute(to_sql)
  end
end