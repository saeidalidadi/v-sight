gulp    = require 'gulp'
coffee  = require 'gulp-coffee'

gulp.task('build', (cb) ->
  gulp.src('./index.coffee')
  .pipe coffee({ bare: true })
  .pipe gulp.dest('.')

  gulp.src('./lib/*.coffee')
  .pipe coffee({bare: true })
  .pipe gulp.dest('./lib')
)

gulp.task('default', ['build'])

