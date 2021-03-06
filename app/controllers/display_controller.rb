class DisplayController < ApplicationController
  def see_class
    if params[:seeClass] != 'No Classes'
      @class_number = params[:seeClass]
      @class_number.slice!'Class '
      cookies[:seeClass] = @class_number
    end
    redirect_to '/'
  end

  def pair
    @student_ids = []
    @pair_results = []
    @students_to_pair = Student.where(class_number: cookies[:seeClass])
    if !@students_to_pair.nil?
      @students_to_pair.each {|student|
        @student_ids << student.id
      }
    end
    @pairs_bad = true
    while @pairs_bad
      @pairs_bad = false
      randomized_ids = form_pairs
    end

    randomized_ids.each {|count|
      @pair_results << "#{Student.find(count).first_name} #{Student.find(count).last_name}"
    }
    cookies[:pair_results] = @pair_results.to_yaml
    @paired_class = cookies[:seeClass].to_i
    cookies[:paired_class] = @paired_class
    redirect_to '/'
  end

  def form_pairs
    if Pair.where(:class_number => @paired_class).maximum('pair_set').nil?
      set_number = 1
    else
      set_number = Pair.where(:class_number => @paired_class).maximum('pair_set') + 1
    end
    count = 0
    randomized = @student_ids.sample(@student_ids.length)
    #alphabetize the pairs
    alphabetized = []
    while count < randomized.length do
      if Student.find(randomized[count]).first_name + Student.find(randomized[count]).last_name < Student.find(randomized[count+1]).first_name + Student.find(randomized[count+1]).last_name
        alphabetized << randomized[count]
        alphabetized << randomized[count+1]
      else
        alphabetized << randomized[count+1]
        alphabetized << randomized[count]
      end
      count += 2
    end
    #reset the counter
    count = 0
    #end alphabetizing
    while count < alphabetized.length do
      if !Pair.where(:first_id => [alphabetized[count], alphabetized[count+1]], :second_id => [alphabetized[count], alphabetized[count+1]]).first.nil?
        @pairs_bad = true
      end
      count += 2
    end
    count = 0
    if !@pairs_bad
      while count < alphabetized.length do
        Pair.create(class_number: cookies[:seeClass].to_i, pair_set: set_number, first_id: alphabetized[count], second_id: alphabetized[count+1], first_full_name: "#{Student.find(alphabetized[count]).first_name} #{Student.find(alphabetized[count]).last_name}", second_full_name: "#{Student.find(alphabetized[count+1]).first_name} #{Student.find(alphabetized[count+1]).last_name}")
        count += 2
      end
    end
    alphabetized
  end

  def enough_pairs
    number_of_slots = 2
    number_of_students = Student.where(:class_number => @paired_class).count
    number_of_pairs = Pair.where(:class_number => @paired_class).count
    number_of_combinations = calc_factorial(number_of_students) / calc_factorial(number_of_slots) * calc_factorial(number_of_students - number_of_slots)
    number_of_combinations - number_of_pairs >= number_of_students/number_of_slots 
  end

  def calc_factorial(num)
    result = 1
    num.times do |element|
      result *= (element+1)
    end
    result
  end
end
