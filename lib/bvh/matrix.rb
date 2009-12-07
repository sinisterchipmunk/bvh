require 'matrix'

class Matrix
  def []=(i,j,x)
    @rows[i][j] = x
  end

  def load_identity!
    row_size.times do |r|
      column_size.times do |c|
        self[r, c] = (r == c ? 1 : 0)
      end
    end
    self
  end
end
