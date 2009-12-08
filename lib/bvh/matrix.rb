require 'matrix'

# This adds a few methods to the default Ruby Matrix implementation.
class Matrix
  # Sets row "i", column "j", to the value "x".
  def []=(i,j,x)
    @rows[i][j] = x
  end

  # Turns this matrix into an identity matrix, erasing all previous values.
  def load_identity!
    row_size.times do |r|
      column_size.times do |c|
        self[r, c] = (r == c ? 1 : 0)
      end
    end
    self
  end
end
