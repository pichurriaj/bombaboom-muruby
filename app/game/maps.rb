
#create array with first layer of map
def _grid_create(srow = 15, scol = 15)
  map = []
  (0...16).each{|row|
    (0...16).each{|col|
      #corner up left
      if row == 0 and col == 0
        map << [11, 0, col, row]
      elsif row == srow and col == 0
        map << [11, 3, col, row]
      elsif row == 0 and col == scol
        map << [11, 1, col, row]
      elsif row == srow and col == scol
        map << [11, 2, col, row]
      elsif row == 0 || row == srow
        map << [13, 5, col, row]
      elsif col == 0 || col == scol
        map << [14, 1, col, row]
      else
        ret = yield(row, col)
        map << ret unless ret.nil?
      end
    }
  }
  map
end


##MAPS

$maps = {
  lost_ruby: {
    name: 'lost ruby',
    data: Proc.new {
      _grid_create do |row, col|
          [0, 0, col, row]
      end
    }.call,
    objects: Proc.new {
      _grid_create do |row, col|
        if row % 3 == 0 and col % 2 == 0
          [11, 4, row, col, :wall]
        elsif row % 7 == 0 and col % 3 == 0
          [10, 5, row, col, :brick]
        else
          nil
        end
      end
    }.call,
  }
}
