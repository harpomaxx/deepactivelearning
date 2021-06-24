import persistent
import BTrees.OOBTree
import re
import tempfile
from subprocess import Popen, PIPE

from stf.common.out import *
from stf.core.dataset import __datasets__
from stf.core.connections import  __group_of_group_of_connections__
from stf.core.models_constructors import __modelsconstructors__ 
from stf.core.notes import __notes__

###############################
###############################
###############################
class Model(persistent.Persistent):
    """
    The Model
    """
    def __init__(self, id):
        self.id = id
        self.state = ''
        self.note_id = False
        self.last_flow_time = ''
        self.constructor = ''
        self.label_id = ''
        self.label_name = ''

    def get_id(self):
        return self.id

    def add_last_flow_time(self,time):
        """ Used to compute during visualizations the time to wait """
        self.last_flow_time = time

    def get_last_flow_time(self):
        try:
            return self.last_flow_time
        except AttributeError:
            return False

    def add_flow(self,flow):
        """ Get a flow and generate a state to store"""
        state = self.constructor.get_state(flow, self.get_id())
        if state:
            self.state += state
            return True
        else:
            return False

    def set_constructor(self,constructor):
        """ Set the constructor of the model"""
        self.constructor = constructor

    def get_constructor(self):
        return self.constructor

    def get_state(self):
        return self.state

    def set_note_id(self, note_id):
        self.note_id = note_id

    def get_note_id(self):
        try:
            return self.note_id
        except KeyError:
            return False

    def edit_note(self, note_id):
        """ Edit a note """
        __notes__.edit_note(note_id)

    def add_note(self):
        """ Add a note to the model """
        note_id = __notes__.new_note()
        self.set_note_id(note_id)

    def del_note(self):
        """ Delete the note related with this model """
        try:
            # First delete the note
            note_id = self.note_id
            __notes__.del_note(note_id)
            # Then delete the reference to the note
            del self.note_id 
        except AttributeError:
            # Note does not exist, but don't print nothing becase there are a lot of models to delete
            pass

    def get_short_note(self):
        """ Return a short text of the note """
        try:
            note_id = self.note_id
            return __notes__.get_short_note(note_id)
        except AttributeError:
            return ''

    def del_label_id(self, label_id):
        """ Del the label id"""
        if self.label_id == label_id:
            self.label_id = False
            self.label_name = ""

    def del_label_name(self, label_name):
        """ Del the label name"""
        try:
            if self.label_name == label_name:
                self.label_name = ""
                self.label_id = False
        except AttributeError:
            # No label name? ok.. carry on
            pass
    def warn_labels(self):
        labelid = self.get_label_id()
        if labelid:
            print_warning('The label {} should be deleted by hand if not used anymore.'.format(self.get_label_id()))

    def set_label_id(self, label_id):
        """ Set the label id"""
        self.label_id = label_id

    def get_label_id(self):
        try:
            return self.label_id
        except AttributeError:
            return False

    def set_label_name(self, name):
        """ Set the label name. We know that this is not ok and we should only store the label id, but we can not cross import modules, so this is the best way I know how to solve it"""
        self.label_name = name

    def get_label_name(self):
        """ Return the label name for this model"""
        try:
            return self.label_name
        except:
            return ''

    def get_flow_label(self, model_group_id):
        """ Returns the label in the first flow on the connections """
        # Horrible to get the model group id in a parameter... i know
        # Get the group of connections id
        group_of_connections_id = int(model_group_id.split('-')[0])
        group_of_connections = __group_of_group_of_connections__.get_group(group_of_connections_id)
        # Get the flow label. This is horrible and we should not do it, but we need to access the first connection in the list... so just access the dict directly...
        connection = group_of_connections.connections[self.get_id()]
        return connection.get_label()



###############################
###############################
###############################
class Group_of_Models(persistent.Persistent):
    def __init__(self, id):
        """ This class holds all the models for a dataset"""
        self.id = id
        self.models = BTrees.OOBTree.BTree()
        self.constructor_id = -1
        self.dataset_id = -1
        self.group_connection_id = -1


    def set_constructor_id(self, constructor_id):
        self.constructor_id = constructor_id

    def get_constructor_id(self):
        try:
            return self.constructor_id
        except AttributeError:
            return 'Not Stored'

    def set_dataset_id(self, dataset_id):
        self.dataset_id = dataset_id

    def get_dataset_id(self):
        return self.dataset_id 

    def set_group_connection_id(self, group_connection_id):
        """ Receives the id of the group of connections that this group of models is related to """
        self.group_connection_id = group_connection_id

    def get_group_connection_id(self):
        return self.group_connection_id

    def get_models(self):
        return self.models.values()

    def get_model(self,id):
        try:
            return self.models[id]
        except KeyError:
            return False

    def get_id(self):
        return self.id

    def generate_models(self):
        """ Generate all the individual models. We are related with only one dataset and connection group. """
        # Get the group of connections from the id
        group_of_connections = __group_of_group_of_connections__.get_group(self.get_group_connection_id())

        # For each connection
        for connection in group_of_connections.get_connections():
            # Create its model. Remember that the connection id and the model id is the 4-tuple
            model_id = connection.get_id()
            new_model = Model(model_id)
            # Set the constructor for this model. Each model has a specific way of constructing the states
            #new_model.set_constructor(__modelsconstructors__.get_default_constructor())
            constructor_id = self.get_constructor_id()
            new_model.set_constructor(__modelsconstructors__.get_constructor(constructor_id))
            for flow in connection.get_flows():
                # Try to add the flow
                if not new_model.add_flow(flow):
                    self.delete_model_by_id(new_model.get_id())
                    # The flows are not ordered. Delete the truckated models
                    __groupofgroupofmodels__.delete_group_of_models(self.get_id())
                    return False
            self.models[model_id] = new_model

    def construct_filter(self, filter):
        """ Get the filter string and decode all the operations """
        # If the filter string is empty, delete the filter variable
        if not filter:
            try:
                del self.filter 
            except:
                pass
            return True
        self.filter = []
        # Get the individual parts. We only support and's now.
        for part in filter:
            # Get the key
            try:
                key = re.split('<|>|=|\!=', part)[0]
                value = re.split('<|>|=|\!=', part)[1]
            except IndexError:
                # No < or > or = or != in the string. Just stop.
                break
            try:
                part.index('<')
                operator = '<'
            except ValueError:
                pass
            try:
                part.index('>')
                operator = '>'
            except ValueError:
                pass
            # We should search for != before =
            try:
                part.index('!=')
                operator = '!='
            except ValueError:
                # Now we search for =
                try:
                    part.index('=')
                    operator = '='
                except ValueError:
                    pass
            self.filter.append((key, operator, value))

    def apply_filter(self, model):
        """ Use the stored filter to know what we should match"""
        responses = []
        try:
            self.filter
        except AttributeError:
            # If we don't have any filter string, just return true and show everything
            return True
        # Check each filter
        for filter in self.filter:
            key = filter[0]
            operator = filter[1]
            value = filter[2]
            if key == 'statelength':
                state = model.get_state()
                if operator == '<':
                    if len(state) < int(value):
                        responses.append(True)
                    else:
                        responses.append(False)
                elif operator == '>':
                    if len(state) > int(value):
                        responses.append(True)
                    else:
                        responses.append(False)
                elif operator == '=':
                    if len(state) == int(value):
                        responses.append(True)
                    else:
                        responses.append(False)
            elif key == 'name':
                name = model.get_id()
                if operator == '=':
                    if value in name:
                        responses.append(True)
                    else:
                        responses.append(False)
                elif operator == '!=':
                    if value not in name:
                        responses.append(True)
                    else:
                        responses.append(False)
            elif key == 'labelname':
                # For filtering based on the label assigned to the model with stf (contrary to the flow label)
                labelname = model.get_label_name()
                if operator == '=':
                    if value in labelname:
                        responses.append(True)
                    else:
                        responses.append(False)
                elif operator == '!=':
                    if value not in labelname:
                        responses.append(True)
                    else:
                        responses.append(False)
            elif key == 'flowlabel':
                flowlabel = model.get_flow_label(self.get_id())
                if operator == '=':
                    if value in flowlabel:
                        responses.append(True)
                    else:
                        responses.append(False)
                elif operator == '!=':
                    if value not in flowlabel:
                        responses.append(True)
                    else:
                        responses.append(False)
            else:
                return False

        for response in responses:
            if not response:
                return False
        return True

    def list_models(self, filter, max_letters=0):
        all_text=' Note | Label | Model Id | State |\n'
        # construct the filter
        self.construct_filter(filter)
        amount = 0
        for model in self.models.values():
            if self.apply_filter(model):
                if max_letters:
                    all_text += '[{:3}] | {:61} | {:50} | {}\n'.format(model.get_note_id() if model.get_note_id() else '', model.get_label_name() if model.get_label_name() else '', cyan(model.get_id()), model.get_state()[:max_letters])
                else:
                    all_text += '[{:3}] | {:61} | {:50} | {}\n'.format(model.get_note_id() if model.get_note_id() else '', model.get_label_name() if model.get_label_name() else '', cyan(model.get_id()), model.get_state())
                amount += 1
        all_text += 'Amount of models printed: {}'.format(amount)
        f = tempfile.NamedTemporaryFile()
        f.write(all_text)
        f.flush()
        p = Popen('less -R ' + f.name, shell=True, stdin=PIPE)
        p.communicate()
        sys.stdout = sys.__stdout__ 
        f.close()

    def export_models(self, filter):
        """ Export the models in this group that match the filter as ascii to a file"""
        # construct the filter
        self.construct_filter(filter)
        f = tempfile.NamedTemporaryFile(mode='w+b', delete=False)
        print 'Storing the models in filename {} using TAB as field separator.'.format(f.name)
        text = 'ModelId\tState\tLabelName\n'
        f.write(text)
        amount = 1
        for model in self.models.values():
            if self.apply_filter(model):
                text = '{}\t{}\t{}\n'.format(model.get_id(), model.get_state(),model.get_label_name())
                f.write(text)
                amount += 1
        f.close()
        print '{} models exported'.format(amount)

    def export_models_to_file(self, filename):
        """ Export the models in this group that match the filter as ascii to a file"""
        # construct the filter
        f =open(filename,mode='w+b')
        print 'Storing the models in filename {} using TAB as field separator.'.format(f.name)
        text = 'ModelId\tState\tLabelName\n'
        f.write(text)
        amount = 1
        for model in self.models.values():
            if self.apply_filter(model):
                text = '{}\t{}\t{}\n'.format(model.get_id(), model.get_state(),model.get_label_name())
                f.write(text)
                amount += 1
        f.close()
        print '{} models exported'.format(amount)




    def delete_model_by_id(self, model_id):
        """ Delete one model given a model id """
        try:
            # Before deleting the model, delete its relation in the constructor
            model = self.models[model_id]
            model.constructor.del_model(model_id)
            # Delete the notes in the model
            model.del_note()
            # Say that the labels should be deleted by hand
            model.warn_labels()
            # Now delete the model
            self.models.pop(model_id)
            return True
        except KeyError:
            print_error('That model does not exists.')
            return False

    def delete_model_by_filter(self, filter):
        """ Delete the models using the filter. Do not delete the related connections """
        # set the filter
        self.construct_filter(filter)
        amount = 0
        ids_to_delete = []
        for model in self.models.values():
            if self.apply_filter(model):
                ids_to_delete.append(model.get_id())
                amount += 1
        # We should delete the models AFTER finding them, if not, for some reason the following model after a match is missed.
        for id in ids_to_delete:
            self.delete_model_by_id(id)
        print_info('Amount of modules deleted: {}'.format(amount))
        # Add an auto note
        self.add_note_to_dataset('{} models deleted from the group id {} using the filter {}.'.format(amount, self.get_id(), filter))

    def count_models(self, filter=''):
        # set the filter
        self.construct_filter(filter)
        amount = 0
        for model in self.models.values():
            if self.apply_filter(model):
                amount += 1
        print_info('Amount of modules filtered: {}'.format(amount))

    def has_model(self, id):
        if self.models.has_key(id):
            return True
        else:
            return False

    def plot_histogram(self, filter):
        """ Plot the histogram of statelengths """
        # Construct the filter
        self.construct_filter(filter)
        """ Plot the histogram of length of states using an external tool """
        dist_path,error = Popen('bash -i -c "type distribution"', shell=True, stderr=PIPE, stdin=PIPE, stdout=PIPE).communicate()
        if not error:
            distribution_path = dist_path.split()[0]
            all_text_state = ''
            for model in self.get_models():
                if self.apply_filter(model):
                    state_len = str(len(model.get_state()))
                    all_text_state += state_len + '\n'
            print 'Key=Length of state'
            Popen('echo \"' + all_text_state + '\" |distribution --height=900 | sort -nk1', shell=True).communicate()
        else:
            print_error('For ploting the histogram we use the tool https://github.com/philovivero/distribution. Please install it in the system to enable this command.')

    def list_notes(self, filter_string=''):
        """ List the notes in all the models """
        all_text='| Note Id | Model Id | Note(...) |\n'
        # construct the filter
        self.construct_filter(filter_string)
        amount = 0
        for model in self.get_models():
            if self.apply_filter(model) and model.get_short_note():
                note_id = model.get_note_id()
                if note_id:
                    all_text += '{} | {:40} | {}\n'.format(note_id, model.get_id(), model.get_short_note())
                    amount += 1
        all_text += 'Amount of models listed: {}'.format(amount)
        f = tempfile.NamedTemporaryFile()
        f.write(all_text)
        f.flush()
        p = Popen('less -R ' + f.name, shell=True, stdin=PIPE)
        p.communicate()
        sys.stdout = sys.__stdout__ 
        f.close()

    def edit_note_in_model(self, model_id):
        """ Edit note in model """
        try:
            model = self.models[model_id]
            if model.get_note_id():
                note_id = model.get_note_id()
                model.edit_note(note_id)
            else:
                print_info('Model {} does not have a note attached yet.'.format(model.get_id()))
                model.add_note()
                note_id = model.get_note_id()
                model.edit_note(note_id)

        except KeyError:
            print_error('That model does not exists.')

    def del_note_in_model(self, model_id):
        """ Delete the note in a model """
        try:
            model = self.models[model_id]
            model.del_note()
        except KeyError:
            print_error('That model does not exists.')

    def add_note_to_dataset(self, text_to_add):
        """ Add an auto note to the dataset where this group of model belongs """
        try:
            note_id = __datasets__.current.get_note_id()
        except AttributeError:
            # The dataset may be already deleted?
            return False
        if note_id:
            __notes__.add_auto_text_to_note(note_id, text_to_add)
        else:
            # There was no note yet. Create it and add the text.
            note_id = __notes__.new_note()
            __datasets__.current.set_note_id(note_id)
            __notes__.add_auto_text_to_note(note_id, text_to_add)



###############################
###############################
###############################
class Group_of_Group_of_Models(persistent.Persistent):
    def __init__(self):
        """ This class holds all the groups of models"""
        self.group_of_models = BTrees.OOBTree.BTree()

    def get_group(self, group_id):
        """ Given the id of a group of models, return its object """
        try:
            return self.group_of_models[group_id]
        except KeyError:
            return False

    def get_groups(self):
        return self.group_of_models.values()

    def get_groups_ids(self):
        return self.group_of_models.keys()

    def list_groups(self):
        print_info('Groups of Models')
        # If we selected a dataset, just print the one belonging to the dataset
        if __datasets__.current:
            rows = []
            for group in self.group_of_models.values():
                if group.get_dataset_id() == __datasets__.current.get_id():
                    rows.append([group.get_id(), group.get_constructor_id(), len(group.get_models()), __datasets__.current.get_id(), __datasets__.current.get_name() ])
            print(table(header=['Group of Model Id', 'Constructor ID', 'Amount of Models', 'Dataset Id', 'Dataset Name'], rows=rows))
        # Otherwise print them all
        else:
            rows = []
            for group in self.group_of_models.values():
                # Get the dataset based on the dataset id stored from this group 
                dataset = __datasets__.get_dataset(group.get_dataset_id())
                rows.append([group.get_id(), group.get_constructor_id(), len(group.get_models()), dataset.get_id(), dataset.get_name() ])
            print(table(header=['Group of Model Id', 'Constructor ID', 'Amount of Models', 'Dataset Id', 'Dataset Name'], rows=rows))

    def delete_group_of_models(self, id):
        """Get the id of a group of models and delete it"""
        try:
            # Get the group
            group = self.group_of_models[id]
        except KeyError:
            print_error('There is no such an id for a group of models.')
            return False
        # First delete all the the models in the group
        ids_to_delete = []
        for model in group.get_models():
            model_id = model.get_id()
            ids_to_delete.append(model_id)

        # We should delete the models AFTER finding them, if not, for some reason the following model after a match is missed.
        amount = 0
        for modelid in ids_to_delete:
            if group.delete_model_by_id(modelid):
                amount += 1
        print_info('Deleted {} models inside the group'.format(amount))

        # Now delete the model
        self.group_of_models.pop(id)
        # Here we should put all the t1 and t2 of the models in zero somehow????
        print_info('Deleted group of models with id {}'.format(id))
        # Add an auto note
        group.add_note_to_dataset('Deleted group of models id {}.'.format(id))

    def delete_group_of_models_with_dataset_id(self, target_dataset_id):
        """Get the id of a dataset and delete all the models that were generated from it"""
        for group in self.group_of_models.values():
            dataset_id_of_group = group.get_dataset_id()
            group_id = group.get_id()
            if dataset_id_of_group == target_dataset_id:
                # First delete all the the models in the group
                group.delete_model_by_filter('statelength>0')
                # Now delete the model
                self.group_of_models.pop(group_id)
                print_info('Deleted group of models with id {}'.format(group_id))

    def generate_group_of_models(self, constructor_id):
        if __datasets__.current:
            # Get the id for the current dataset
            dataset_id = __datasets__.current.get_id()
            # We should check that there is a group of connections already for this dataset
            if not __group_of_group_of_connections__.get_group(dataset_id):
                # There are not group of connections for this dataset, just generate it
                print_info('There were no connections for this dataset. Generate them first.')
                return False

            # Get the id of the groups of connections these models are related to
            group_connection = __group_of_group_of_connections__.get_group(dataset_id)
            if group_connection:
                group_connection_id = group_connection.get_id()
            else:
                print_error('There are no connections for this dataset yet. Please generate them.')

            # The id of this group of models is the id of the dataset + the id of the model constructor. Because we can have the same connnections modeled by different constructors.
            #group_of_models_id = str(dataset_id) + '-' + str(__modelsconstructors__.get_default_constructor().get_id())
            group_of_models_id = str(dataset_id) + '-' + str(constructor_id)

            # If we already have a group of models, ask what to do
            try:
                group_of_models = self.group_of_models[group_of_models_id]
                print_warning('There is already a group of models for this dataset. Do you want to delete the current models and create a new one?')
                answer = raw_input('YES/NO?')
                if answer == 'YES':
                    # First delete the old models
                    self.delete_group_of_models(group_of_models_id)
                else:
                    return False
            except KeyError:
                # first time. Not to repeat the code, we leave this empty and we do a new try
                pass

            # Do we have the group of models for this id?
            try:
                group_of_models = self.group_of_models[group_of_models_id]
            except KeyError:
                # First time.
                # Create the group of models
                group_of_models = Group_of_Models(group_of_models_id)
                # Set the group of connections they will be using
                group_of_models.set_group_connection_id(group_connection_id)
                # Set the dataset id for this group of models
                group_of_models.set_dataset_id(dataset_id)
                # Set the model constructor used for all the models
                group_of_models.set_constructor_id(constructor_id)
                # Store the model
                self.group_of_models[group_of_models_id] = group_of_models
                # Update the dataset to include this group of models
                __datasets__.current.add_group_of_models(group_of_models_id)

            # Generate the models
            group_of_models.generate_models()
        else:
            print_error('There is no dataset selected.')

    def list_models_in_group(self, id, filter, max_letters=0):
        try:
            group = self.group_of_models[id]
            group.list_models(filter, max_letters)
        except KeyError:
            print_error('Inexistant id of group of models.')

    def export_models_in_group(self, id, filename):
        try:
            group = self.group_of_models[id]
            group.export_models_to_file(filename)
        except KeyError:
            print_error('Inexistant id of group of models.')

    def delete_a_model_from_the_group_by_id(self, group_of_models_id, model_id):
        # Get the id of the current dataset
        if __datasets__.current:
            try:
                group_of_models = self.group_of_models[group_of_models_id]
            except KeyError:
                print_error('No such group of models id available.')
                return False
            group_of_models.delete_model_by_id(model_id)
            # Add an auto note
            group_of_models.add_note_to_dataset('Model {} deleted from the group of models id {}.'.format(model_id, group_of_models.get_id()))
        else:
            # This is not necesary to work, but is a nice precaution
            print_error('There is no dataset selected.')

    def delete_a_model_from_the_group_by_filter(self, group_of_models_id, filter=''):
        # Get the id of the current dataset
        if __datasets__.current:
            try:
                group_of_models = self.group_of_models[group_of_models_id]
            except KeyError:
                print_error('No such group of models id available.')
                return False
            group_of_models.delete_model_by_filter(filter)
        else:
            # This is not necesary to work, but is a nice precaution
            print_error('There is no dataset selected.')

    def count_models_in_group(self, id, filter=''):
        try:
            group = self.group_of_models[id]
            group.count_models(filter)
        except KeyError:
            print_error('No such group of models.')

    def plot_histogram(self, group_of_models_id, filter=""):
        try:
            group = self.group_of_models[group_of_models_id]
            group.plot_histogram(filter)
        except KeyError:
            print_error('No such group of models.')

    def edit_note(self, group_of_models_id, model_id):
        """ Get a model id and edit its note """
        if __datasets__.current:
            try:
                group_of_models = self.group_of_models[group_of_models_id]
            except KeyError:
                print_error('There is no model group with that id')
                return False
            try:
                group_of_models.edit_note_in_model(model_id)
            except KeyError:
                print_error('No such model id.')
        else:
            print_error('There is no dataset selected.')

    def del_note(self, group_of_models_id, model_id): 
        """ Get a model id and delete its note """
        if __datasets__.current:
            group_of_models = self.group_of_models[group_of_models_id]
            try:
                group_of_models.del_note_in_model(model_id)
            except KeyError:
                print_error('No such model id.')
        else:
            print_error('There is no dataset selected.')

    def list_notes(self, group_of_models_id, filter=""):
        """ List the notes in a group_of_models """
        if __datasets__.current:
            group_of_models = self.group_of_models[group_of_models_id]
            group_of_models.list_notes(filter)
        else:
            print_error('There is no dataset selected.')


        

__groupofgroupofmodels__ = Group_of_Group_of_Models()
