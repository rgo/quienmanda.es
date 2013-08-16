require 'spec_helper'

describe Importer do
  context 'when importing a fact' do
    before do
      @husband = create(:public_person, name: 'Adam')
      @relation = create(:relation_type, description: 'is married to')
      @wife = create(:public_person, name: 'Eve')
      @importer = Importer.new
    end

    it 'returns matched attributes' do
      match = @importer.match( [create(:fact, source: 'Adam', role: 'is married to', target: 'Eve')] )
      match.size.should == 1
      match.first.should == { source: @husband, relation_type: @relation, target: @wife }
    end

    it 'property names are configurable' do
      custom_importer = Importer.new(source_name: 'Who', role_name: 'What', target_name: 'To whom')
      custom_fact = Fact.new(properties: { 'Who' => 'Adam', 'What' => 'is married to', 'To whom' => 'Eve'})
      match = custom_importer.match([custom_fact])
      match.first.should == { source: @husband, relation_type: @relation, target: @wife }
    end
  end

  context 'when using a preprocessor' do
    before do
      @husband = create(:public_person, name: 'Adam')
      @married = create(:relation_type, description: 'is married to')
      @friends = create(:relation_type, description: 'is friends with')
      @wife = create(:public_person, name: 'Eve')
      @importer = Importer.new
    end

    it 'applies the preprocessing before matching' do
      # Add a spellchecker as a preprocessor
      spellchecker = ->(fact) { fact.properties[:role] = "is married to"; fact }
      @importer.preprocessor = spellchecker

      match = @importer.match( [create(:fact, source: 'Adam', role: 'is maried to', target: 'Eve')] )
      match.first.should == { source: @husband, relation_type: @married, target: @wife }
    end

    it 'the preprocessor can delete facts' do
      # Add a filter as a preprocessor, return an empty array to ignore a fact
      filter = ->(fact) { [] }
      @importer.preprocessor = filter

      match = @importer.match( [create(:fact, source: 'Adam', role: 'is married to', target: 'Eve')] )
      match.should == []
    end

    it 'the preprocessor can add facts' do
      # Add a filter as a preprocessor, return nil to ignore a fact
      splitter = ->(fact) do
        another_fact = create(:fact, source: 'Adam', role: 'is friends with', target: 'Eve')
        fact.properties[:role] = 'is married to'
        [fact, another_fact]
      end
      @importer.preprocessor = splitter

      match = @importer.match( [create(:fact, source: 'Adam', role: 'is married to / is friends with', target: 'Eve')] )
      match.should =~ [ { source: @husband, relation_type: @married, target: @wife },
                        { source: @husband, relation_type: @friends, target: @wife } ] 
    end
  end

  context 'after importing a fact' do
    before do
      @that_obama_guy = create(:public_person, name: 'Obama')
      @director_relation = create(:relation_type, description: 'president')
      @that_country = create(:public_organization, name: 'USG')
      @importer = Importer.new
    end

    it 'keeps track of non-matched relation types' do
      @importer.match( [create(:fact, role: 'a role')] )
      @importer.relation_types.size.should == 1
      @importer.relation_types['a role'][:count].should == 1
      @importer.relation_types['a role'][:object].should == nil
    end

    it 'keeps track of matched relation types' do
      @importer.match( [create(:fact, role: 'president')] )
      @importer.relation_types.size.should == 1
      @importer.relation_types['president'][:count].should == 1
      @importer.relation_types['president'][:object].should == @director_relation
    end

    it 'keeps track of non-matched source entities' do
      @importer.match( [create(:fact, source: 'a guy')] )
      @importer.entities.size.should == 2   # Includes target entity
      @importer.entities['a guy'][:count].should == 1
      @importer.entities['a guy'][:object].should == nil
    end

    it 'keeps track of matched source entities' do
      @importer.match( [create(:fact, source: 'Obama')] )
      @importer.entities.size.should == 2   # Includes target entity
      @importer.entities['Obama'][:count].should == 1
      @importer.entities['Obama'][:object].should == @that_obama_guy
    end

    it 'keeps track of non-matched target entities' do
      @importer.match( [create(:fact, target: 'an organization')] )
      @importer.entities.size.should == 2   # Includes source entity
      @importer.entities['an organization'][:count].should == 1
      @importer.entities['an organization'][:object].should == nil
    end

    it 'keeps track of matched target entities' do
      @importer.match( [create(:fact, target: 'USG')] )
      @importer.entities.size.should == 2   # Includes source entity
      @importer.entities['USG'][:count].should == 1
      @importer.entities['USG'][:object].should == @that_country
    end
  end
end