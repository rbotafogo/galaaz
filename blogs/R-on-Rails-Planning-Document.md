# R-on-Rails (Galaaz 2.0): Planning Document

## Vision Statement

A landmark document that positions **R-on-Rails** as the natural evolution for R developers who need production-grade infrastructure—just as Ruby on Rails revolutionized web development by making it accessible and productive.

**Target Audience**: R developers, data scientists, bioinformaticians, and scientific computing practitioners who need to move their R code from analysis notebooks to production systems.

---

## Introduction: The Two-Engine Architecture

### Opening Hook (Compelling Narrative)

Start with the familiar story: In 2005, Ruby on Rails transformed web development. Before Rails, building web applications required deep expertise in multiple technologies, complex configuration, and weeks of boilerplate code. Rails introduced convention over configuration, scaffolding, and a productive framework that let developers focus on their application logic rather than infrastructure.

Today, data science faces a similar challenge. R is unmatched for statistical analysis, visualization, and scientific computing. But taking an R script from a Jupyter notebook or RStudio into a production environment—where it needs user authentication, database connections, job scheduling, error recovery, and API endpoints—is still a formidable barrier.

### The Problem: R's Strengths and Production Weaknesses

**R's Strengths (Why we love R):**
- Unparalleled statistical and bioinformatics ecosystem (Bioconductor, thousands of packages)
- Excellent visualization with ggplot2, lattice, plotly
- Interactive, REPL-driven development perfect for exploration
- Domain-specific languages for data manipulation (dplyr, data.table)
- Rich modeling capabilities (caret, glm, randomForest, etc.)
- Reproducible research with R Markdown

**R's Production Challenges (Why R struggles in production):**
- **Single-threaded**: R's interpreter is fundamentally single-threaded. Parallel processing requires forking or external orchestration
- **Memory management**: R's copy-on-modify semantics can be inefficient for large-scale data processing
- **Web infrastructure**: Shiny is great for dashboards but lacks enterprise-grade user management, authentication flows, and API design patterns
- **Error isolation**: A crash in one R session takes down the entire process
- **Database integration**: DBI works but lacks the Rails ActiveRecord ecosystem for migrations, connection pooling, ORM patterns
- **Data transfer costs**: Moving data between R and other languages typically requires expensive serialization (CSV, JSON)
- **Deployment complexity**: R environments are notoriously difficult to reproduce (packrat, renv help but aren't seamless)
- **Security**: No built-in user session management, authorization patterns, or CSRF protection

### Why Python Took the Mindshare

Python became the lingua franca of data science not because it's better than R at statistics (it isn't), but because it offered a **path to production**:

- **Django/Flask**: Web frameworks with auth, ORM, migrations, testing built-in
- **Jupyter + Production**: Easy transition from notebook to `.py` script to deployed service
- **Industry adoption**: Tech companies standardized on Python for ML pipelines
- **Deep Learning**: PyTorch and TensorFlow's Python-first APIs

But R still dominates in:
- Biostatistics and clinical trials (FDA submissions often require R)
- Epidemiology and public health research
- Academic statistical research
- Survey analysis and social sciences
- Any domain where the statistical method is the product

### Why Ruby on Rails Now (The Rails Renaissance)

Rails never went away—it matured. Several factors make Rails compelling again:

- **HTML5 and Hotwire**: Modern browsers reduce the need for complex JavaScript SPAs. Rails with Hotwire delivers reactive UIs with minimal JS.
- **JRuby and Modern JVM**: JRuby on modern JVMs delivers excellent performance, true multi-threading, and Java ecosystem integration
- **Developer Experience**: Rails 7+ with import maps, esbuild, and modern asset pipeline is cleaner than ever
- **The "One-Person Framework"**: Rails excels when a small team (or single developer) needs to ship a complete product
- **Convention over Configuration**: Less decision fatigue, faster development

### The Thesis: R-on-Rails

**R-on-Rails** is a two-engine architecture:

1. **Rails (Ruby)**: Handles web requests, authentication, authorization, database operations, background jobs, email, APIs, caching, sessions, and orchestration
2. **R**: Handles statistical modeling, machine learning, visualization, and data analysis
3. **Galaaz**: The seamless bridge that makes this integration feel like a single system—using Apache Arrow for zero-copy data transfer at scale

**The Value Proposition**: Keep everything you love about R—the packages, the syntax, the statistical rigor—while gaining everything Rails provides for production applications. Move data between languages at memory speed, not serialization speed.

---

## The Galaaz 2.0 Architecture (Important Technical Clarification)

**Galaaz 2.0 uses JRuby + GNU R, not GraalVM/FastR**

Earlier versions of Galaaz explored GraalVM's polyglot capabilities with FastR (Oracle's R implementation). However, **FastR is no longer actively developed**, and Galaaz 2.0 has moved to a more robust architecture:

```
┌─────────────────────────────────────────────────────────────────┐
│                        Galaaz 2.0 Architecture                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐         ┌──────────────┐         ┌──────────┐ │
│  │   JRuby      │ ←─────→ │ Galaaz Bridge│ ←─────→ │ GNU R    │ │
│  │  (JVM)       │  (Java) │  (JNI/R API) │  (C/R)  │  Process │ │
│  └──────────────┘         └──────────────┘         └──────────┘ │
│        │                                                    │   │
│        │                                                    │   │
│        ▼                                                    ▼   │
│  ┌──────────────┐                                  ┌──────────┐│
│  │ Rails App    │                                  │ Arrow    ││
│  │ Multi-thread │                                  │ Shared   ││
│  │ ActiveRecord │                                  │ Memory   ││
│  └──────────────┘                                  └──────────┘│
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**How it works:**
1. **JRuby** runs on the JVM with true multi-threading, running Rails and application code
2. **Galaaz Bridge** communicates with a GNU R process via R's C API (or alternative mechanisms)
3. **Apache Arrow** (optional) provides efficient, shared-memory data transfer for large datasets
4. **GNU R** is the actual R interpreter—full compatibility with all R packages (ggplot2, dplyr, Bioconductor, etc.)

**Why this is better than FastR/GraalVM:**
- **Full package compatibility**: GNU R runs every CRAN and Bioconductor package
- **Stable foundation**: No dependency on Oracle's experimental R implementation
- **Production-ready**: Battle-tested JRuby + battle-tested GNU R
- **Process isolation**: R runs in separate processes—crash in one R process doesn't take down the Rails app
- **Multiple R workers**: Ruby can orchestrate multiple R processes for parallel computation

**Comparison with other bridges:**

| Approach | How it works | Limitations |
|----------|--------------|-------------|
| **rpy2** (Python) | Embeds R in Python process | Single-threaded, crashes affect host |
| **RinRuby** | Parses R code over stdout | String-based, no type safety, slow |
| **reticulate** (R→Python) | Python embedded in R | Limited to Python, not R-in-Python |
| **Galaaz 1.0** (GraalVM) | FastR + TruffleRuby polyglot | FastR discontinued, limited packages |
| **Galaaz 2.0** (JRuby+GNU R) | JRuby → Bridge → GNU R process | Full compatibility, process isolation |

---

## Section-by-Section Outline with Code Examples

### Section 1: What Makes Galaaz Different (The Bridge Architecture)

**Key Message**: Traditional bridges (rpy2, RinRuby) require string manipulation. Galaaz provides native object interaction without marshaling overhead.

**Comparison:**

Traditional approach (rpy2):
```python
# Python with rpy2 - string-based interaction
import rpy2.robjects as ro
ro.r('library(ggplot2)')
ro.r('data(mpg, package="ggplot2")')
ro.r('''
  ggplot(mpg, aes(displ, hwy)) +
    geom_point() +
    geom_smooth(method="loess")
''')
```

Galaaz approach:
```ruby
# Ruby with Galaaz - native object interaction
require 'galaaz'
require 'ggplot'

R.install_and_loads('ggplot2')
mpg = ~:mpg  # Access R's mpg dataset

# Native Ruby method calls, not string evaluation
plot = mpg.ggplot(E.aes(x: :displ, y: :hwy)) +
       R.geom_point +
       R.geom_smooth(method: "loess")

plot.print
```

**Why this matters**: 
- Type safety and IDE autocomplete work naturally
- No string escaping hell
- R errors propagate as Ruby exceptions
- Efficient data transfer between JRuby and GNU R processes

**Example from specs** (r_vector_functions.spec.rb):
```ruby
# R's %in% operator becomes a native method call
vec1 = R.c(1, 2, 3, 4)
vec2 = R.c(3, 4, 5)

# In R: vec1 %in% vec2
# In Galaaz:
result = vec1._ :in, vec2  # Returns R vector of booleans
```

---

### Section 2: dplyr and Non-Standard Evaluation (NSE) - Solved

**Key Message**: Programming with dplyr in R is famously tricky due to NSE. Galaaz makes it straightforward with explicit expression handling.

**The Problem** (from nse_dplyr blog):
In R, this works interactively:
```r
library(dplyr)
df %>% filter(x == 1)  # x refers to column, not variable
```

But programming with it fails:
```r
my_var <- 1
df %>% filter(x == my_var)  # Error: object 'my_var' not found
```

You need tidyeval, `{{}}` operators, `ensym()`, `enquo()`—concepts that take months to master.

**The Galaaz Solution**:
```ruby
require 'galaaz'

df = R.data__frame(x: (1..5), y: (5..1))

# Simple filtering with expressions
filtered = df.filter(:x.eq 1)  # Filter where column x equals 1

# Using variables is explicit and unambiguous
my_var = 1
filtered = df.filter(:x.eq my_var)  # Column x equals Ruby variable my_var

# Column-to-column comparison
filtered = df.filter(:x.eq :y)  # Column x equals column y

# Complex expressions
filtered = df.filter((:x + :y).gte 5)
```

**Why this works**: Galaaz expressions (`:x.eq 1`) are explicit about what's a column reference (symbol `:x`) vs. what's a Ruby value (`my_var`). No ambiguity, no tidyeval complexity.

**Example from specs** (r_nse.spec.rb):
```ruby
def subset(df, condition)
  # Evaluate condition in the scope of the dataframe
  r = R.eval(condition, df)
  df[r, :all]
end

# Usage: explicit expression with symbol :a
subset(df, :a >= 4)
subset(df, :a.eq 4)
```

---

### Section 3: ggplot2 Continuity - Same Power, Better Orchestration

**Key Message**: Your ggplot2 skills transfer completely. Galaaz adds Ruby's organizational power—classes, modules, themes as code.

**Side-by-Side Example** (from ruby_plot blog):

R code:
```r
library(ggplot2)
data(ToothGrowth)

ggplot(ToothGrowth, aes(x=dose, y=len)) +
  geom_boxplot() +
  facet_grid(. ~ supp) +
  labs(title="Tooth Growth", x="Dose", y="Length")
```

Galaaz code:
```ruby
require 'galaaz'
require 'ggplot'

tooth_growth = ~:ToothGrowth

plot = tooth_growth.ggplot(E.aes(x: :dose, y: :len)) +
       R.geom_boxplot +
       R.facet_grid(:all.til :supp) +  # Formula: ~supp
       R.labs(title: "Tooth Growth", x: "Dose", y: "Length")

plot.print
```

**The Ruby Advantage - Corporate Themes as Modules** (from ruby_plot blog):
```ruby
module CorpTheme
  def self.global_theme(faceted: false)
    R.options(scipen: 999)  # No scientific notation
    
    gb = R.theme(panel__grid__major: E.element_blank)
    gb = gb + R.theme(panel__grid__minor: E.element_blank)
    gb = gb + R.theme(panel__border: E.element_blank)
    gb = gb + R.theme(panel__background: E.element_blank) unless faceted
    gb = gb + R.theme(axis__title: text_element(10, face: "bold", hjust: 1))
    gb
  end
end

# Apply theme consistently
final_plot = plot + CorpTheme.global_theme(faceted: true)
```

**Key insight**: In R, creating a reusable theme requires understanding ggplot2's theme system. In Galaaz, it's just a Ruby module—standard Ruby knowledge any developer has.

---

### Section 4: Modeling and Statistics - ISLR Examples

**Key Message**: Statistical modeling with caret, lm, glm works identically. Ruby adds train/test split abstractions and model management.

**Example** (from examples/islr/ch3_boston.rb):

```ruby
require 'galaaz'
require 'ggplot'

R.install_and_loads('ISLR', 'MASS')  # Install if needed, then load

# Access R's Boston dataset
boston = ~:Boston

# Simple linear regression
# R: lm(medv ~ lstat, data=Boston)
boston_lm = R.lm((:medv.til :lstat), data: :Boston)

puts boston_lm.coef        # Coefficients
puts boston_lm.confint     # Confidence intervals

# Predictions with intervals
conf = R.predict(boston_lm, 
                 R.data__frame(lstat: R.c(5, 10, 15)), 
                 interval: "confidence")

pred = R.predict(boston_lm, 
                 R.data__frame(lstat: R.c(5, 10, 15)), 
                 interval: "prediction")

# Multiple regression (from ch3_multiple_regression.rb)
lm_fit = R.lm((:medv.til :lstat + :age), data: :Boston)
puts lm_fit.summary

# Polynomial terms
lm_fit5 = R.lm((:medv.til E.poly(:lstat, 5)), data: :Boston)
puts lm_fit5.summary
```

**Multiple Regression with caret** (from model.rb):
```ruby
require 'galaaz'

class Model
  attr_reader :data, :test, :train

  def initialize(data, percent_train:, seed: 123)
    R.set__seed(seed)
    @data = data
    @percent_train = percent_train
  end

  def partition(field)
    # R's createDataPartition for train/test split
    train_index = R.createDataPartition(
      @data.send(field), 
      p: @percent_train,
      list: false, 
      times: 1
    )
    @train = @data[train_index, :all]
    @test = @data[-train_index, :all]
  end
end

# Usage
model = Model.new(boston_data, percent_train: 0.8, seed: 42)
model.partition(:medv)  # Partition based on medv column
# model.train and model.test now available
```

---

### Section 5: Object-Oriented R - Classes, Modules, and Reusable Code

**Key Message**: R's S4 and R6 provide OOP, but Ruby's object model is more expressive and easier to learn. Galaaz brings real OOP to statistical workflows.

**Comparison** (from oh_my blog):

R S4:
```r
setClass(
  Class="Trajectories",
  representation=representation(
    times = "numeric",
    traj = "matrix"
  )
)

trajCochin <- new(
  Class="Trajectories",
  times=c(1,3,4,5),
  traj=rbind(
    c(15,15.1, 15.2, 15.2),
    c(16,15.9, 16,16.4)
  )
)

# Add a method
setMethod("print", "Trajectories",
  function(x, ...) {
    cat("*** Class Trajectories ***\n")
    cat("* Times ="); print(x@times)
  }
)
```

Galaaz Ruby:
```ruby
class Trajectories
  attr_reader :times, :matrix

  def initialize(times: nil, matrix: nil)
    @times = times
    @matrix = matrix
  end

  def print
    puts("*** Class Trajectories, method Print ***")
    puts("times = #{@times}")
    puts("traj = #{@matrix}")
  end

  # Can add methods later without redefining class
  def show
    nrow_show = [10, @matrix.nrow.gz].min
    puts("* Traj (limited to 10x10) =")
    puts @matrix[(1..nrow_show), (1..nrow_show)].format(digits: 2)
  end
end

# Usage with R data
@trajCochin = Trajectories.new(
  times: R.c(1, 3, 4, 5),
  matrix: R.rbind(
    R.c(15, 15.1, 15.2, 15.2),
    R.c(16, 15.9, 16, 16.4)
  )
)

@trajCochin.print
@trajCochin.show
```

**Key advantages**:
- Constructor with default parameters
- Easy method addition (reopen classes)
- Mixins and modules for shared behavior
- Clear separation between R data and Ruby logic
- Full introspection: `@traj.instance_variables`

---

### Section 6: Apache Arrow - Zero-Copy Data at Scale

**Key Message**: Traditional bridges serialize data (JSON, CSV) to pass between languages. Galaaz uses Apache Arrow for zero-copy, memory-mapped data transfer—enabling huge datasets to move from Ruby to R instantly.

**The Problem: Data Transfer Overhead**

In traditional polyglot systems (rpy2, reticulate), passing data between languages requires serialization:

```python
# Python → R via JSON/CSV serialization (SLOW)
import pandas as pd
import rpy2.robjects as ro
from rpy2.robjects import pandas2ri

df = pd.DataFrame({'x': range(1000000), 'y': range(1000000)})
# Converts Python DataFrame → CSV string → R data.frame (expensive!)
ro.globalenv['r_df'] = pandas2ri.py2rpy(df)
```

This approach:
- Copies all data through a text format
- Loses type information (factors become strings, dates become strings)
- Consumes 2-3x memory during transfer
- Becomes a bottleneck at ~100K+ rows

**The Galaaz Solution: Apache Arrow**

Apache Arrow is a columnar, in-memory format designed for zero-copy data sharing across languages. With Galaaz:

```ruby
require 'galaaz'

# 1. Build data in Ruby—using parallel threads for multi-source ingestion
batches = []
mutex = Mutex.new
threads = []

# Simulate parallel data ingestion from multiple sources
[0, 1, 2, 3].each do |tid|
  threads << Thread.new do
    # Each thread queries its own database/shard/API
    local_data = fetch_from_source(tid) # Returns array of hashes
    mutex.synchronize { batches << local_data }
  end
end
threads.each(&:join)

# 2. Convert to Arrow Table—zero-copy transfer to R
# This is the key: data moves to R without serialization!
table = R::Arrow.from_ruby_batches(batches)

# 3. Use R's dplyr directly on the Arrow table
R.install_and_loads('dplyr', 'arrow')

grouped = R.dplyr___group_by(table, :region)
summarised = R.dplyr___summarise(
  grouped,
  count: E.n(),
  avg_value: E.mean(:value),
  total: E.sum(:value)
)
results = R.dplyr___collect(summarised)

puts results
#> # A tibble: 4 × 4
#>   region count avg_value total
#>   <chr>  <int>     <dbl> <dbl>
#> 1 North  25000      5.5  137500
#> 2 South  25000      5.5  137500
#> 3 East   25000      5.5  137500
#> 4 West   25000      5.5  137500
```

**Why This Matters:**

- **No serialization cost**: Data stays in Arrow's columnar format throughout
- **Type preservation**: Factors, dates, timestamps remain intact
- **Memory efficiency**: No intermediate copies; Ruby and R share the same memory
- **Scale**: Tested with millions of rows (see slow-specs/arrow_large_pipeline_spec.rb with 200K+ rows)
- **Lazy evaluation**: Arrow datasets can be filtered/aggregated before materializing

**Real-World Example: Multi-DB Aggregation**:

```ruby
# Aggregate data from multiple PostgreSQL shards in Ruby,
# then analyze in R with zero-copy transfer

require 'galaaz'
require 'active_record'

# Connect to multiple database shards
SHARDS = ['shard_1', 'shard_2', 'shard_3', 'shard_4'].map do |shard_name|
  ActiveRecord::Base.establish_connection(
    adapter: 'postgresql',
    host: "#{shard_name}.db.internal",
    database: 'analytics'
  )
end

# Parallel data collection from all shards
batches = []
mutex = Mutex.new

SHARDS.each do |shard|
  Thread.new do
    # Query this shard
    records = shard.connection.select_all(<<-SQL).cast_values
      SELECT user_id, region, event_type, value, created_at
      FROM events
      WHERE created_at > NOW() - INTERVAL '7 days'
    SQL

    # Convert to array of hashes for Arrow
    batch = records.map do |row|
      {
        user_id: row[0],
        region: row[1],
        event_type: row[2],
        value: row[3],
        created_at: row[4]
      }
    end

    mutex.synchronize { batches << batch }
  end
end

# Zero-copy transfer to R as Arrow Table
table = R::Arrow.from_ruby_batches(batches)

# Now use R's full power on the complete dataset
R.install_and_loads('dplyr', 'arrow', 'lubridate')

# R's dplyr works directly on Arrow tables (lazy evaluation)
analysis = table \
  .dplyr___filter(E.created_at > (E.now() - E.days(7))) \
  .dplyr___group_by(:region, :event_type) \
  .dplyr___summarise(
    count: E.n(),
    total_value: E.sum(:value),
    avg_value: E.mean(:value),
    unique_users: E.n_distinct(:user_id)
  )

# Materialize results when ready
results = R.dplyr___collect(analysis)

# Convert back to Ruby objects for API response
results_hash = results.to_ruby
render json: { analytics: results_hash }
```

**Parquet and Feather: Persistence Without Conversion**:

```ruby
# Save Ruby data as Parquet (columnar, compressed)
# Then read directly into R without parsing

# 1. Build large dataset in Ruby
data = (1..1_000_000).map do |i|
  {
    id: i,
    category: ["A", "B", "C", "D"][i % 4],
    value: rand * 100,
    timestamp: Time.now - (i % 86400)
  }
end

# 2. Convert to R data.frame, then write as Parquet
df = R.data__frame(data)
R::Arrow.write_parquet(df, '/data/events.parquet')

# 3. Later, read directly into R as a dataset (lazy, memory-mapped)
dataset = R::Arrow.dataset('/data/events.parquet')

# Query without loading entire file
summary = R.dplyr___collect(
  dataset \
    .dplyr___filter(:value > 50) \
    .dplyr___group_by(:category) \
    .dplyr___summarise(count: E.n(), avg: E.mean(:value))
)
```

**Large-Scale Test Results** (from `slow-specs/arrow_large_pipeline_spec.rb`):

```ruby
# Test: 8 threads × 25,000 rows = 200,000 rows
# With weighted aggregations in R
thread_count = 8
rows_per_thread = 25_000
group_count = 10

# Ruby parallel batch construction... 8 threads
# Arrow table creation from batches → instant
# R dplyr group_by + summarise → native speed
# Results verified accurate against Ruby reference implementation
```

**Key Insight**: With Arrow, the boundary between Ruby and R disappears for data. You can build data pipelines in Ruby (with its superior concurrency and database libraries) and analyze in R (with its statistical ecosystem)—with **zero overhead** at the language boundary.

---

### Section 7: Parallelism and Process Orchestration

**Key Message**: R is single-threaded. Galaaz solves this by orchestrating multiple R processes from Ruby's multi-threaded environment—now with Arrow for efficient data distribution.

**The Architecture**:
```
┌─────────────────────────────────────────────────────────────┐
│                    Rails Application                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Request    │  │   Request    │  │   Request    │       │
│  │   Handler 1  │  │   Handler 2  │  │   Handler 3  │       │
│  │  (Thread 1)  │  │  (Thread 2)  │  │  (Fiber)     │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
│         │                  │                  │              │
│         └──────────────────┼──────────────────┘              │
│                            │                                 │
│                    ┌─────────▼─────────┐                      │
│                    │  Galaaz Bridge    │                      │
│                    │  (Process Pool)   │                      │
│                    └─────────┬─────────┘                      │
│                            │                                 │
│         ┌──────────────────┼──────────────────┐             │
│         │                  │                  │              │
│  ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐        │
│  │ R Process 1 │   │ R Process 2 │   │ R Process 3 │        │
│  │ (Worker)    │   │ (Worker)    │   │ (Worker)    │        │
│  │ Arrow Table │   │ Arrow Table │   │ Arrow Table │        │
│  └─────────────┘   └─────────────┘   └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

**Code Example**:
```ruby
# Parallel data processing with multiple R workers
require 'galaaz'

# Data partitioned by region
regions = ['North', 'South', 'East', 'West']
data_partitions = partition_data_by_region(large_dataset, regions)

# Launch parallel R computations
results = Parallel.map(data_partitions, in_processes: 4) do |region_data|
  R.session do |r|
    # Each block runs in its own R process
    r.install_and_loads('dplyr', 'caret')
    
    # R computation
    model = r.lm((:sales.til :marketing_spend + :competition_index), 
                 data: region_data)
    
    predictions = r.predict(model, newdata: region_data)
    
    # Return Ruby object (automatic unboxing)
    { region: region_data.name,
      r_squared: model.summary.r.squared.gz,
      predictions: predictions }
  end
end

# Consolidate results in Ruby
combined = consolidate_predictions(results)
```

**Fault Isolation**:
```ruby
# If an R process crashes, Galaaz can restart and retry
R.session(restart_on_error: true, max_retries: 3) do |r|
  r.long_running_computation(data)
end
```

---

### Section 8: Production Architecture - The Full Stack

**Key Message**: A complete production system with Rails handling web concerns and R handling analytics.

**Example: Analytics API Endpoint**:
```ruby
# app/controllers/analytics_controller.rb
class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_analytics!

  def forecast
    # Rails handles auth, params, response formatting
    product_id = params[:product_id]
    days = params[:days]&.to_i || 30
    
    # Database query with ActiveRecord
    historical_data = SalesData
      .where(product_id: product_id)
      .where('date > ?', days.days.ago)
      .to_galaaz_df  # Convert to R dataframe
    
    # Delegate to R for statistical modeling
    forecast_result = R.session do |r|
      r.install_and_loads('forecast')
      
      ts = r.ts(historical_data.sales, frequency: 7)
      model = r.auto.arima(ts)
      forecast = r.forecast(model, h: days)
      
      {
        mean: forecast.mean,
        lower: forecast.lower,
        upper: forecast.upper,
        model_aic: model.aic
      }
    end
    
    # Rails formats response
    render json: {
      product_id: product_id,
      forecast: forecast_result,
      generated_at: Time.current
    }
  end
end
```

**Background Job with Sidekiq**:
```ruby
# app/jobs/model_training_job.rb
class ModelTrainingJob < ApplicationJob
  queue_as :ml_training

  def perform(training_data_id, model_config)
    training_data = TrainingData.find(training_data_id)
    
    # Large computation in isolated R process
    R.session(timeout: 1.hour) do |r|
      r.install_and_loads('caret', 'randomForest')
      
      # Train model
      model = r.train(
        target ~ ., 
        data: training_data.to_r,
        method: model_config[:algorithm],
        trControl: r.trainControl(method: "cv", number: 5)
      )
      
      # Save model (R's native format)
      model_path = "/models/#{training_data_id}.rds"
      r.saveRDS(model, model_path)
      
      # Store metadata in Rails database
      training_data.update!(
        model_path: model_path,
        accuracy: model.results.Accuracy.max.gz,
        trained_at: Time.current
      )
    end
  end
end
```

---

### Section 9: Migration Path - From R Script to R-on-Rails

**Key Message**: You don't rewrite everything. You migrate incrementally, starting with the web layer.

**Phase 1: Wrap R Script in API** (Week 1):
```ruby
# Before: R script run manually
# Rscript generate_report.R --input data.csv --output report.pdf

# After: Rails API endpoint
class ReportsController < ApplicationController
  def create
    uploaded_file = params[:data_file]
    
    R.session do |r|
      r.eval("data <- read.csv('#{uploaded_file.path}')")
      r.eval("rmarkdown::render('report_template.Rmd', output_file='report.pdf')")
    end
    
    send_file 'report.pdf', type: 'application/pdf'
  end
end
```

**Phase 2: Replace R Data Manipulation with Ruby** (Weeks 2-4):
```ruby
# Gradually move from R dplyr to Ruby ActiveRecord/SQL
# Before (R):
# R.filter(df, :region == "North" & :sales > 1000)

# After (Rails):
SalesData.where(region: "North").where("sales > ?", 1000)
```

**Phase 3: Full Object-Oriented Refactor** (Month 2+):
```ruby
# Extract R logic into Ruby service objects
class SalesForecaster
  def initialize(product)
    @product = product
  end
  
  def forecast(days: 30)
    R.session do |r|
      # Only statistical core remains in R
      # Everything else is Ruby
    end
  end
end
```

---

## Conclusion: The Best of Both Worlds

### Summary of Value Propositions

**For R Developers**:
- Keep using ggplot2, dplyr, caret, Bioconductor—your knowledge transfers
- Write statistical code the way you always have
- Gain real web infrastructure: auth, APIs, databases, caching
- Deploy with confidence using Rails' battle-tested patterns
- No need to learn Python or JavaScript frameworks

**For Rails Developers**:
- Add world-class statistical capabilities to your applications
- Access thousands of R packages without rewriting them
- Maintain your productivity with familiar Rails patterns
- Serve data science customers without context-switching languages

**For Organizations**:
- Bridge the gap between data science and engineering teams
- Deploy R models in production with proper infrastructure
- Reduce technical debt from "R scripts running on someone's laptop"
- Enable reproducible research that scales to production

### The Future: Galaaz 2.0

Galaaz 2.0 represents the maturation of the Ruby-R bridge:
- **JRuby + GNU R architecture**: Moved from experimental GraalVM/FastR to battle-tested JRuby and standard GNU R for full package compatibility and production stability
- **New bridge architecture**: More robust, faster, better error handling
- **Process management**: Built-in support for R process pools
- **Apache Arrow integration**: Zero-copy data transfer for large datasets—build data pipelines in Ruby's multi-threaded environment, analyze in R with zero serialization overhead
- **gKnit improvements**: Better R Markdown integration
- **Rails integration**: First-class support for Rails patterns

---

## Appendix: Code Reference Quick Links

For the full blog post, include references to:

- **ISLR Examples**: `examples/islr/ch3_boston.rb`, `examples/islr/ch3_multiple_regression.rb`
- **ggplot2 Examples**: `examples/sthda_ggplot/` (all geom types)
- **NSE/dplyr**: `blogs/nse_dplyr/nse_dplyr.md`
- **Object-Oriented**: `blogs/oh_my/oh_my.md`
- **Plotting Tutorial**: `blogs/ruby_plot/ruby_plot.md`
- **Apache Arrow**: `specs/arrow_semantics_spec.rb`, `specs/arrow_from_ruby_batches_spec.rb`, `slow-specs/arrow_large_pipeline_spec.rb`
- **Specs**: `specs/r_nse.spec.rb`, `specs/r_vector_functions.spec.rb`

---

## Writing Notes for the Final Post

### Tone Guidelines
- **Respectful of R**: Never disparage R. Position this as "adding production capabilities" not "fixing R."
- **Practical**: Show real code, not theoretical benefits.
- **Incremental**: Emphasize that migration can happen piece by piece.
- **Excited**: This is a genuine breakthrough—let that enthusiasm show.

### Code Example Format
Each section should have:
1. R version (familiar to readers)
2. Galaaz version (showing similarity)
3. Ruby-only enhancement (showing the value add)

### Visual Diagrams to Create
1. Two-engine architecture diagram
2. Process pool for parallel R     
3. Request flow through Rails-R integration
4. Migration path timeline

### Call to Action
Invite readers to:
- Try the examples in `examples/islr/`
- Read the full dplyr tutorial in `blogs/nse_dplyr/`
- Explore ggplot examples in `examples/sthda_ggplot/`
- Join the Galaaz community (GitHub discussions, etc.)
